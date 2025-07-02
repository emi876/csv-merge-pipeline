import os
import boto3
import csv
from io import StringIO
import logging
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

def lambda_handler(event, context):
    logger.info("Lambda triggered")

    input_bucket = os.environ.get("INPUT_BUCKET")
    output_bucket = os.environ.get("OUTPUT_BUCKET")
    anxiety_key = os.environ.get("ANXIETY_KEY")
    demographics_key = os.environ.get("DEMOGRAPHICS_KEY")
    output_key = os.environ.get("OUTPUT_KEY", "processed/merged.csv")

    if not all([input_bucket, output_bucket, anxiety_key, demographics_key]):
        logger.error("Missing one or more required environment variables (INPUT_BUCKET, OUTPUT_BUCKET, ANXIETY_KEY, DEMOGRAPHICS_KEY).")
        return {"status": "failed", "message": "Missing environment variables"}

    try:
        # Read CSVs from S3
        anxiety_data = read_csv_from_s3(input_bucket, anxiety_key)
        demographics_data = read_csv_from_s3(input_bucket, demographics_key)

        logger.info(f"Read {len(anxiety_data)} rows from {anxiety_key}")
        logger.info(f"Read {len(demographics_data)} rows from {demographics_key}")

        # Convert demographics_data into a dictionary for efficient lookup (HID as key)
        # Based on SF_HOMELESS_DEMOGRAPHICS.csv, 'HID' column already exists and is formatted.
        demographics_lookup = {}
        for row in demographics_data:
            # Safely get the 'HID' value. This prevents KeyError if 'HID' is genuinely missing from a row.
            demographics_hid = row.get("HID")
            if demographics_hid: # Only add to lookup if 'HID' exists AND is not an empty string
                demographics_lookup[demographics_hid] = row
            else:
                logger.warning(f"Demographics row skipped (missing or empty 'HID' value): {row}")


        merged_rows = []
        # Process anxiety data, normalize Homeless ID, and perform merge
        for anxiety_row in anxiety_data:
            original_homeless_id = anxiety_row.get("Homeless ID")
            if original_homeless_id:
                # Normalize Homeless ID to HID format: 'HM15-1' -> '001-15'
                try:
                    numeric_part = re.sub(r"HM15-", "", str(original_homeless_id), count=1)
                    if not numeric_part.isdigit():
                        raise ValueError("Numeric part is not digits")

                    hid = f"{int(numeric_part):03d}-15"
                    anxiety_row["HID"] = hid # Add HID to anxiety row for consistency in merged output
                except (ValueError, KeyError) as e:
                    logger.warning(f"Skipping anxiety row due to invalid 'Homeless ID' format: '{original_homeless_id}'. Error: {e}")
                    continue # Skip this row if ID is malformed

                # Perform the inner join
                if hid in demographics_lookup:
                    merged_row = {**anxiety_row, **demographics_lookup[hid]}
                    merged_rows.append(merged_row)
                else:
                    logger.debug(f"No matching demographic data found for HID: {hid}. Anxiety row skipped.")
            else:
                logger.warning(f"Skipping anxiety row as 'Homeless ID' is missing: {anxiety_row}")


        logger.info(f"Merged {len(merged_rows)} rows successfully.")

        if not merged_rows:
            logger.warning("No rows merged. Output file will contain only headers or be empty if no headers determined.")

        # Determine all unique headers for the merged CSV
        all_headers = set()
        if merged_rows:
            for row in merged_rows:
                all_headers.update(row.keys())
        else:
            # If no rows merged, get headers from original inputs to still provide a schema.
            # This is a fallback to ensure an output file with headers, even if empty.
            for row in anxiety_data:
                all_headers.update(row.keys())
            for row in demographics_data:
                all_headers.update(row.keys())

        sorted_headers = sorted(list(all_headers))

        # Write merged CSV to S3
        output_buffer = StringIO()
        writer = csv.DictWriter(output_buffer, fieldnames=sorted_headers)
        writer.writeheader()
        writer.writerows(merged_rows)

        s3.put_object(
            Bucket=output_bucket,
            Key=output_key,
            Body=output_buffer.getvalue().encode("utf-8"),
            ContentType="text/csv"
        )

        logger.info(f"Wrote merged file to s3://{output_bucket}/{output_key}")
        return {"status": "success", "output_key": output_key}

    except Exception as e:
        logger.error(f"An error occurred: {e}", exc_info=True)
        return {"status": "failed", "message": str(e)}

def read_csv_from_s3(bucket, key):
    """Reads a CSV file from S3 and returns its content as a list of dictionaries."""
    logger.info(f"Attempting to read s3://{bucket}/{key}")
    try:
        obj = s3.get_object(Bucket=bucket, Key=key)
        csv_string = obj["Body"].read().decode("utf-8")
        reader = csv.DictReader(StringIO(csv_string))
        return list(reader)
    except s3.exceptions.NoSuchKey:
        logger.error(f"S3 object not found: s3://{bucket}/{key}")
        raise FileNotFoundError(f"CSV file not found: {key} in bucket {bucket}")
    except Exception as e:
        logger.error(f"Error reading CSV from S3: s3://{bucket}/{key}. Error: {e}", exc_info=True)
        raise