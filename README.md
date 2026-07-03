# Thin-File Credit Scoring: Payment Behaviour as an Alternative to Bureau History

An analysis of whether loan repayment behaviour can predict default for thin-file and no-bureau borrowers, and what that implies for credit assessment under Canada's incoming open banking framework.

## Executive Summary

**Repayment behaviour predicts loan default even for borrowers with no credit history, and predicts it more strongly than for borrowers who have one.**

Traditional assessment relies on bureau history, which leaves 42% of applicants in this dataset (thin-file and no-bureau borrowers) difficult to score. Using the Home Credit dataset as a proxy for open-banking transaction data, this project tested whether payment behaviour could assess them instead. The results:

- **Late payers default more in every segment.** Thin-file borrowers: 8.1% on-time vs 13.4% late. Bureau borrowers: 7.3% vs 10.2%.
- **The signal is strongest where bureau data is weakest.** The on-time-to-late gap is wider for thin-file borrowers (5.3 points) than for those with credit history (2.9 points).
- **A model trained only on bureau borrowers transferred to thin-file borrowers it had never seen**, confirming the pattern is not confined to established borrowers.

Thin-file applicants are declined because they are invisible to the bureau, not because they are proven risks. Their behaviour is both visible and predictive, which supports approving more creditworthy newcomers while also sharpening risk assessment for borrowers who already have credit files. This project used payment behaviour alone by design; richer open-banking variables (income, employment length, household, education) are the next step toward pricing individual risk rather than ranking segments.

## Dashboard

<img width="1267" height="692" alt="Thin-File Credit Scoring Dashboard" src="https://github.com/user-attachments/assets/40f4a3c7-5a71-477f-a740-fa7bf8ea3ceb" />
## Context

Credit assessment in Canada rests on bureau history: a record of prior borrowing and repayment held by Equifax and TransUnion. The model works well for established borrowers and poorly for everyone else. Newcomers, young applicants, and anyone outside the formal credit system present a thin file or no file at all, and are frequently declined not because they are high-risk, but because they are unscored.

This gap is now a live regulatory and commercial question. Canada's Consumer-Driven Banking Act, which establishes the country's open banking framework, received Royal Assent in 2024, with the framework's initial phase covering read access to consumer financial data expected to come into force in 2025-2026 and broader functionality following. For the first time, lenders will be able to access an applicant's actual transaction and payment behaviour directly from their accounts, with consent, rather than inferring risk from a bureau file that may not exist.

That shift raises a concrete question this project tests: **for borrowers the bureau cannot see, does observed payment behaviour carry enough signal to assess default risk fairly?**

## Data

[Home Credit Default Risk](https://www.kaggle.com/competitions/home-credit-default-risk) (Kaggle), 307,511 loan applicants. Three tables were used:

| Table | Contents |
|-------|----------|
| `application_train` | One row per applicant, including the default outcome (`TARGET`) |
| `installments_payments` | Individual scheduled payments and whether each was made on time |
| `bureau` | Prior credit records from other lenders, used to classify bureau history |

The dataset serves as a proxy for open-banking-style data. It does not contain live bank statements, but installment payment history stands in reasonably for the repayment behaviour an open banking feed would expose.

## Method

### 1. Segmentation and exploration (SQL, DBeaver)

Applicants were classified by bureau depth:

| Profile | Definition | Share of applicants |
|---------|------------|:-------------------:|
| Has bureau history | 2+ bureau records | 58% |
| No bureau history | No bureau record | 29% |
| Thin file | 1 bureau record | 13% |

Thin-file and no-bureau borrowers together represent **42% of applicants**, a substantial population underserved by conventional scoring. Exploratory queries established that default rates rose consistently as payment behaviour deteriorated, and that the relationship persisted within the thin-file segment.

### 2. Modelling (Python, scikit-learn)

The design isolates the question of transferability. The model was trained exclusively on borrowers **with** bureau history, then evaluated on thin-file and no-bureau borrowers held out entirely from training. This replicates the operational reality of scoring an applicant the lender has no prior visibility into.

- **Features:** payment behaviour only (share of payments on time, average days late, count of late payments). Income, employment, and demographic fields were deliberately excluded to isolate behavioural signal.
- **Model:** logistic regression, selected for interpretability. Each coefficient is directly explainable to a credit or risk stakeholder, which matters more in a regulated lending context than marginal predictive gains from an opaque model.
- **Class imbalance:** handled via balanced class weighting, given the ~8% base default rate.

### 3. Segment comparison

Default rates were compared directly across bureau status and payer type, providing a transparent, group-level view alongside the model.

## Results

Payment behaviour separates defaulters from non-defaulters in both populations:

| Segment | On-time payer | Late payer |
|---------|:-------------:|:----------:|
| Has bureau history | 7.3% | 10.2% |
| Thin file / No bureau | 8.1% | 13.4% |

Two findings follow:

1. **The relationship holds regardless of bureau status.** Late payers default at materially higher rates in both segments, confirming that repayment behaviour is predictive independent of credit file depth.
2. **The signal is stronger where bureau data is weakest.** The on-time-to-late spread is wider for thin-file and no-bureau borrowers (5.3 points) than for those with bureau history (2.9 points). Behavioural data is most informative precisely for the segment traditional scoring serves least well.

This is the core commercial case for behavioural scoring under open banking: the applicants hardest to assess conventionally are the ones whose behaviour reveals the most.

## Model Performance and Interpretation

The logistic regression achieved an **AUC of 0.56** on the held-out thin-file segment. This is a modest figure, and interpreting it correctly is central to the analysis rather than incidental to it.

The group-level relationship is strong, but individual-level ranking is constrained by the distribution of the data: the large majority of borrowers pay on time, so most applicants are near-identical on the three behavioural features available. Late payment moves an applicant's default probability from roughly 8% to 13%, which is actionable for risk-based pricing and limit-setting, but insufficient to rank individuals sharply on so few inputs.

The implication is not that behavioural scoring underperforms, but that a narrow set of loan-repayment features is a floor rather than a ceiling. A production open banking feed would supply materially richer signal (income regularity and volatility, rent and utility payment timing, cash-flow buffers, recurring obligations) none of which this dataset contains. A high AUC on three features would warrant scrutiny; a modest, well-understood AUC is the more credible result.

## Conclusion

- Repayment behaviour predicts default for thin-file and no-bureau borrowers, not only for those with established credit files.
- The predictive signal is strongest for the segment conventional scoring underserves, which is the segment open banking is positioned to reach.
- Loan-repayment history alone is sufficient to demonstrate the relationship but not to price individual risk precisely; the richer data available under open banking is the practical path to doing so.

Conventional scoring declines thin-file borrowers because it cannot observe them. This analysis indicates their behaviour is both observable and predictive, and that Canada's open banking framework is the mechanism to act on it.

## Tools

| Stage | Tools |
|-------|-------|
| Segmentation and exploration | SQL (DBeaver) |
| Feature engineering and modelling | Python (pandas, scikit-learn, Google Colab) |
| Visualisation | Power BI *(in progress)* |

## Repository Structure

```
thin-file-credit-scoring/
├── README.md
├── sql/
│   └── applicant_profile.sql
├── notebook/
│   └── credit_scoring_thin_file_analysis.ipynb
└── dashboard/
    └── (Power BI, in progress)
```

## Disclaimer

The Home Credit dataset is a public proxy for open-banking-style data and does not represent any Canadian lender or borrower. All figures reflect the dataset, not the Canadian market. This project demonstrates analytical method and reasoning and is not a production credit model. References to the Consumer-Driven Banking Act reflect the framework's status as of early 2026; readers should confirm current implementation timelines.
