import ipaddress
import json
import logging
import os
import ssl
import time
import urllib.parse
import urllib.request

import boto3
from botocore.exceptions import ClientError

log = logging.getLogger()
log.setLevel(logging.INFO)


# loading settings
TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
ALLOWLIST = [ipaddress.ip_network(n.strip()) for n in os.environ["ALLOWLIST"].split(",") if n.strip()]
BLOCK_SECONDS = int(os.environ.get("BLOCK_HOURS", "24")) * 3600
PFSENSE_URL = os.environ["PFSENSE_URL"]
BLOCK_ALIAS = os.environ["BLOCK_ALIAS"]
API_KEY = boto3.client("ssm").get_parameter(
    Name=os.environ["PFSENSE_KEY_PARAM"], WithDecryption=True
)["Parameter"]["Value"]

# cert checks off for pfsense
TLS = ssl.create_default_context()
TLS.check_hostname = False
TLS.verify_mode = ssl.CERT_NONE


def handler(event, context): # function to go through messages and tell lambda what failed
    failures = []
    for record in event["Records"]:
        try:
            process(json.loads(record["body"]))
        except Exception:
            log.exception("failed to process message %s", record["messageId"])
            failures.append({"itemIdentifier": record["messageId"]})
    # Only the failed messages go back to the queue (and towards the DLQ)
    return {"batchItemFailures": failures}


def process(notification): # checking if message is alerting
    for alert in notification.get("alerts", []):
        if alert.get("status") != "firing":
            log.info("SKIP %s alert for %s", alert.get("status"), alert.get("src_ip"))
            continue
        handle_firing(alert)


def handle_firing(alert): # function runs checks on each alert
    #  Only act on a real IP address
    raw_ip = alert.get("src_ip", "")
    try:
        ip = str(ipaddress.ip_address(raw_ip))
    except ValueError:
        log.warning("SKIP invalid src_ip %r", raw_ip)
        return

    #  Never block specific infrastructure (predefined)
    if any(ipaddress.ip_address(ip) in net for net in ALLOWLIST):
        log.info("SKIP %s is on the allow-list", ip)
        return

    # Only act once per attacker while the incident is open
    if already_handled(ip):
        log.info("SKIP %s already handled", ip)
        return

    # Block it and if that fails release the lock so the retry can try again
    try:
        block_ip(ip)
    except Exception:
        TABLE.delete_item(Key={"src_ip": ip})
        raise

    # Reporting incident goes to CloudWatch Logs
    log.info(
        "ACTION blocked %s on pfSense alias %s playbook=%s host=%s severity=%s summary=%r",
        ip, BLOCK_ALIAS, alert.get("playbook"), alert.get("host"),
        alert.get("severity"), alert.get("summary"),
    )


def already_handled(ip): # add blocked IP to DB and checks if an ip already is blocked
    """Mark the IP as handled; True if it already was (and not expired)."""
    now = int(time.time())
    try:
        TABLE.put_item(
            Item={"src_ip": ip, "expires_at": now + BLOCK_SECONDS},
            ConditionExpression="attribute_not_exists(src_ip) OR expires_at < :now",
            ExpressionAttributeValues={":now": now},
        )
        return False
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return True
        raise


def block_ip(ip): # add the IP to BLOCK_ALIAS in pfsense
    """Add the IP to the pfSense alias that the block rules use, apply, then verify."""
    alias = find_alias()
    if ip in alias["address"]:
        log.info("%s is already in %s", ip, BLOCK_ALIAS)
        return

    pfsense("PATCH", "/api/v2/firewall/alias", {"id": alias["id"], "address": alias["address"] + [ip]})
    pfsense("POST", "/api/v2/firewall/apply")

    # make sure the IP really ended up in the block alias and not somewhere else
    if ip not in find_alias()["address"]:
        raise RuntimeError(f"{ip} was not added to {BLOCK_ALIAS}")


def find_alias(): # get all aliases and pick the block alias by its name
    aliases = pfsense("GET", "/api/v2/firewall/aliases")["data"]
    for alias in aliases:
        if alias["name"] == BLOCK_ALIAS:
            return alias
    raise RuntimeError(f"alias {BLOCK_ALIAS} not found on pfSense")


def pfsense(method, path, body=None): # for establishing connection to pfsense API
    """Call the pfSense REST API; raises on any HTTP error or timeout."""
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        PFSENSE_URL + path,
        data=data,
        method=method,
        headers={"X-API-Key": API_KEY, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, context=TLS, timeout=4) as resp:
        return json.loads(resp.read())
