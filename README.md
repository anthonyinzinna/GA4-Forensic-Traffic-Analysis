# GA4 Forensic Traffic Analysis

**Advanced SQL pipeline for Google Analytics 4 (BigQuery). Implements identity resolution logic to filter developer traffic, identify high-value recruiters, and calculate true engagement metrics.**

## Objective
To engineer a clean, actionable data pipeline that resolves the "Identity Crisis" in standard web analytics. By moving beyond aggregate vanity metrics, this project uses SQL heuristics to distinguish between **Developer Testing** (me), **Automated Bots** (0s duration), and **High-Value Leads** (Recruiters from LinkedIn/GitHub).

## Executive Summary of Capabilities
Here is a summary of the three key engineering outcomes from this pipeline:

* **Identity Resolution:** Does the traffic come from a real user or the developer?
  * **Logic:** Implements a multi-factor heuristic combining Geolocation (City), Device (OS), and Behavioral Frequency.
  * **Outcome:** Successfully isolates "Developer Traffic" (testing spikes) from "Real User Traffic," preventing data skew during development cycles.

* **Lead Scoring:** Is the visitor a technical hiring manager or a generalist?
  * **Logic:** Parses referral strings to distinguish between **Technical Leads** (GitHub referrers) and **Social Leads** (LinkedIn/Twitter referrers).
  * **Outcome:** Enables granular tracking of portfolio performance across different professional networks.

* **True Engagement Calculation:** Did the user actually read the content?
  * **Logic:** Replaces standard "Bounce Rate" with a calculated `avg_seconds_on_site` derived from unnested event timestamps.
  * **Outcome:** Filters out "0-second" bot traffic (e.g., Headless Chrome crawlers) to reveal the actual engagement time of human visitors (avg. 45s+).

## Methodology & Tech Stack
* **Data Warehouse:** Google BigQuery (GA4 Export)
* **Language:** Standard SQL (BigQuery Dialect)
* **Visualization:** Looker Studio
* **Key Techniques:**
  * **`UNNEST` Function:** Flattens the complex JSON-like `event_params` array to extract hidden metrics like `ga_session_id` and `engagement_time_msec`.
  * **Window Functions:** Scopes engagement metrics to the Session level rather than the Event level.
  * **`CASE` Logic:** Applies business rules to classify users into "Developer," "Recruiter," or "Global User" buckets.

## Forensic Interpretation 🧠
This project reframes raw logs into a forensic narrative:
* **The "Hyderabad Phantom" (Bot Detection):** The pipeline identified high-frequency traffic from Hyderabad with `0s` engagement. By correlating the timestamps (simultaneous hits) and user agent behavior, the logic correctly classified this as **Automated Trust & Safety Audits** (likely Google/recruitment verification bots) rather than human traffic.
* **The "Local Recruiter" (Lead Detection):** By filtering out my own device (iPhone/Mac in Brandon/Flowood), the remaining local traffic revealed genuine network interest, distinguishing "friends and family" visits from "hiring manager" visits based on engagement time (>30s).

## Final Technical Takeaway
**From "Hits" to "Humans"**
The primary achievement of this SQL view is the shift from *Event-based* analytics to *Entity-based* analytics. Standard GA4 dashboards count clicks; this pipeline counts **People**. This distinction is critical for low-volume, high-stakes environments (like a portfolio site during a job hunt) where every single visitor represents a potential interview.
