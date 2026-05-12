# rdl_email_campaigns

## Purpose
Rdl Email Campaigns — RDL layer model

## Grain
One row per (campaign_id, send_date, brand) per ingestion version

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| campaign_id | varchar | Campaign identifier |
| campaign_name | varchar | Campaign name |
| campaign_type | varchar | Campaign type |
| subject_line | varchar | Subject line |
| date_nk | varchar(100) | Canonical date key (standardised from source date column) |
| send_timestamp | varchar | Send timestamp |
| list_size | varchar | List size |
| delivered | varchar | Delivered |
| opened | varchar | Opened |
| unique_opens | varchar | Unique opens |
| clicked | varchar | Clicked |
| unique_clicks | varchar | Unique clicks |
| unsubscribed | varchar | Unsubscribed |
| bounced | varchar | Bounced |
| spam_complaints | varchar | Spam complaints |
| converted | varchar | Converted |
| revenue | varchar | Revenue |
| open_rate | varchar | Open rate |
| click_rate | varchar | Click rate |
| click_to_open_rate | varchar | Click to open rate |
| conversion_rate | varchar | Conversion rate |
| revenue_per_email | varchar | Revenue per email |
| brand | varchar | Boohoo Group brand name |
| ingest_date | date | Date this version was loaded from source |
| ingest_ts | timestamp | Precise ingestion timestamp |
| row_version | integer | 1 = latest version, 2 = previous, etc. |
| is_latest | boolean | TRUE for the most recent version of this record |
| version_count | integer | Total number of versions for this record |
| record_hash | varchar(200) | MD5 hash of all business columns for change detection |

## Key business rules
- Row versioning by (campaign_id, send_date, brand), ordered by ingest_date DESC, ingest_ts DESC
- ALL historical versions retained — no dedup filter applied
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Record hash (MD5 of business columns) for change detection

## Upstream inputs
- `source('rdl_marketing', 'email_campaigns_history')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
Medium
