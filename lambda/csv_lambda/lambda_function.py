import os
import boto3
import pandas as pd
from io import StringIO
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

def lambda_handler(event, context):
    logger.info("Lambda triggered")

    input_bucket = os.environ["INPUT_BUCKET"]
    output_bucket = os.environ["OUTPUT_BUCKET"]
    anxiety_key = os.environ["ANXIETY_KEY"]
    demographics_key = os.environ["DEMOGRAPHICS_KEY"]
    output_key = os.environ.get("OUTPUT_KEY", "processed/merged.csv")

    # Read CSVs from S3
    anxiety_df = read_csv_from_s3(input_bucket, anxiety_key)
    demographics_df = read_csv_from_s3(input_bucket, demographics_key)

    # Normalize Homeless ID → HID format: 'HM15-1' → '001-15'
    anxiety_df["HID"] = (
        anxiety_df["Homeless ID"]
        .str.replace("HM15-", "", regex=False)
        .astype(int)
        .apply(lambda x: f"{x:03d}-15")
    )

    # Merge on HID
    merged_df = pd.merge(anxiety_df, demographics_df, on="HID", how="inner")
    logger.info(f"Merged {len(merged_df)} rows")

    # Write merged CSV to S3
    csv_output = merged_df.to_csv(index=False)
    s3.put_object(
        Bucket=output_bucket,
        Key=output_key,
        Body=csv_output.encode("utf-8"),
        ContentType="text/csv"
    )

    logger.info(f"Wrote merged file to s3://{output_bucket}/{output_key}")
    return {"status": "success"}

def read_csv_from_s3(bucket, key):
    logger.info(f"Reading s3://{bucket}/{key}")
    obj = s3.get_object(Bucket=bucket, Key=key)
    return pd.read_csv(StringIO(obj["Body"].read().decode("utf-8")))
