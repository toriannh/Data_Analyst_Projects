import os
import random
import uuid
from datetime import datetime, timedelta, timezone

import snowflake.connector


EVENT_TYPES = ["SEND", "DELIVERED", "OPEN", "CLICK", "BOUNCE", "UNSUBSCRIBE"]


def sf_connect():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],      # e.g. "TAFTZBS-NI64954"
        user=os.environ["SNOWFLAKE_USER"],           # "TORIANNH"
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
        warehouse=os.environ.get("SNOWFLAKE_WAREHOUSE", "TRANSFORM_WH"),
        database=os.environ.get("SNOWFLAKE_DATABASE", "ANALYTICS_DEV"),
        schema=os.environ.get("SNOWFLAKE_SCHEMA", "RAW"),
	paramstyle="qmark",
    )


def fetch_campaign_ids(cur, limit=200):
    cur.execute(f"select campaign_id from {os.environ.get('SNOWFLAKE_DATABASE','ANALYTICS_DEV')}.RAW.CAMPAIGNS where campaign_id is not null limit {limit}")
    return [r[0] for r in cur.fetchall()]


def generate_events(campaign_ids, n=500, orphan_rate=0.03, null_campaign_rate=0.05):
    """
    Creates n synthetic rows that look like Marketing Cloud event logs.
    - orphan_rate: % with campaign_id that doesn't exist in CAMPAIGNS (intentional DQ)
    - null_campaign_rate: % with NULL campaign_id (intentional DQ)
    """
    now = datetime.now(timezone.utc)

    rows = []
    for _ in range(n):
        event_id = str(uuid.uuid4())
        event_type = random.choices(
            EVENT_TYPES,
            weights=[0.20, 0.20, 0.25, 0.20, 0.10, 0.05],
            k=1
        )[0]

        # recent timestamps (simulate “new” data arriving today)
        event_ts = now - timedelta(minutes=random.randint(0, 24 * 60))

        subscriber_key = f"sub_{random.randint(1, 12000)}"  # matches your seed-ish scale
        division = random.choice(["North", "South", "East", "West"])
        message_id = f"msg_{random.randint(1, 5000)}"

        # is_unique: only really meaningful for OPEN/CLICK in many email systems
        if event_type in ("OPEN", "CLICK"):
            is_unique = random.random() < 0.6
        else:
            is_unique = False

        r = random.random()
        if r < null_campaign_rate:
            campaign_id = None
        elif r < null_campaign_rate + orphan_rate:
            campaign_id = "ORPHAN_" + str(uuid.uuid4())[:8]
        else:
            campaign_id = random.choice(campaign_ids)

        rows.append((
            event_id,
            event_type,
            event_ts.replace(tzinfo=None),  # Snowflake TIMESTAMP_NTZ expected
            subscriber_key,
            campaign_id,
            division,
            message_id,
            is_unique
        ))

    return rows


def main():
    n = int(os.environ.get("MOCK_EVENT_ROWS", "500"))

    conn = sf_connect()
    try:
        cur = conn.cursor()
        campaign_ids = fetch_campaign_ids(cur)

        if not campaign_ids:
            raise RuntimeError("No campaign_ids found in RAW.CAMPAIGNS. Seed/load campaigns first.")

        rows = generate_events(campaign_ids, n=n)

        insert_sql = """
            insert into ANALYTICS_DEV.RAW.MARKETING_CLOUD_EVENTS
            (event_id, event_type, event_ts, subscriber_key, campaign_id, division, message_id, is_unique)
            values (?, ?, ?, ?, ?, ?, ?, ?)
        """

        cur.executemany(insert_sql, rows)
        conn.commit()

        print(f"Inserted {len(rows)} mock Marketing Cloud events into ANALYTICS_DEV.RAW.MARKETING_CLOUD_EVENTS")

    finally:
        try:
            cur.close()
        except Exception:
            pass
        conn.close()


if __name__ == "__main__":
    main()

