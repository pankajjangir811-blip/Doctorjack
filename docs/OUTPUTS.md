# Output Reference

Each execution creates a timestamped directory such as `recon/run_2026-06-20_12-30-00/`.

| File | Purpose |
|---|---|
| `input_prepared.txt` | Normalized, unique HTTP/HTTPS input URLs. |
| `alive.txt` | URLs accepted by the configured HTTP status-code filter. |
| `clean.txt` | Normalized and deduplicated URLs. |
| `split_params.txt` | One query parameter per URL for analysis. |
| `sqli_params.txt` | Candidates matching the installed GF SQLi pattern. |
| `reflected.txt` | Candidates where the parameter appears reflected. |
| `non_reflected_sqli_candidates.txt` | SQLi-pattern candidates not reflected in the response. |
| `dynamic_only.txt` | Candidate URLs showing basic response-metadata differences. |
| `manual_review_priority.txt` | Deduplicated shortlist for manual review. |
| `final_review.tsv` | Categorized findings and review notes. |
| `parameter_type_analysis.tsv` | Parameter type, score, priority, and suggested review approach. |
| `vulnerability_testing_plan.tsv` | Structured review plan. |
| `vulnerability_testing_plan.html` | Browser-readable dashboard/report. |
| `report_data.json` | Structured data used by the report. |
| `metadata.txt` | Run settings, paths, versions, and audit details. |
| `logs/` | Tool errors and diagnostic output. |

A candidate is not proof of a vulnerability. Confirm findings manually and safely within the authorized scope.
