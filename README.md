# Superstore Sales Analysis

A full-stack sales performance analysis built with SQL, Python, and Power BI. The project interrogates four years of transactional data from a US retail superstore (2014–2017) to answer one question a Sales Director would actually ask: where are we losing money, and why?

This is not a dashboard exercise. It is a structured analytical project with a data layer, an exploratory analysis layer, and a presentation layer that produces actionable findings rather than observations.

---

## What this project covers

The analysis runs across 9,988 order lines, 793 customers, 17 product sub-categories, and four US sales regions. The work moves from raw data through SQL transformation, Python-based EDA, and a three-page Power BI report built on a proper star schema with DAX measures.

The five findings that anchor the report:

**Three sub-categories are selling at a loss.** Tables, Bookcases, and Supplies generate a combined net loss of $22,387 on $368K of revenue. All three carry average discounts above 20%. The problem is not the products, it is the discount policy applied to them.

**The margin cliff is at 20% discount.** Orders with no discount generate 29.5% margin. Orders discounted above 20% generate negative 37.3% margin. 1,020 orders in that band produced a net loss of $135,376, subsidised by the profitable zero-discount book of business.

**Central region operates at half the portfolio margin.** At 7.9% margin against a portfolio average of 12.5%, Central is the single largest geographic drag on profitability. West, by comparison, runs at 14.9%. The gap is structural and unresolved.

**The customer base is sticky, the problem is margin per transaction, not retention.** 87.5% of customers placed four or more orders over four years. The business does not have a churn problem. It has a profitability-per-order problem that discounting is making worse.

**Revenue rank is a misleading proxy for customer value.** The top revenue customer (Sean Miller, $25K) generates a net loss of $1,980. The second-ranked customer (Tamara Chand, $19K) generates $8,981 at 47% margin. Sales effort allocated by revenue rank is actively misdirected.

---

## Project structure

```
superstore-sales-analysis/
├── sql/
│   ├── 01_schema_setup.sql
│   ├── 02_vw_margin_by_discount_band.sql
│   ├── 03_vw_revenue_vs_profit_rank.sql
│   ├── 04_vw_subcategory_margin_trend.sql
│   ├── 05_vw_new_vs_returning_margin.sql
│   ├── 06_vw_ship_cost_as_pct_order.sql
│   └── 07_vw_small_order_profitability.sql
├── notebook/
│   ├── superstore_eda.ipynb
│   ├── requirements.txt
│   └── .env.example
└── powerbi/
    └── superstore_analysis.pbix
```

---

## SQL layer

Six analytical views built on MySQL 8.0, each answering a specific business question rather than just aggregating data.

`vw_margin_by_discount_band` classifies every order line into four discount tiers and computes weighted margin per tier, revenue and profit share, and deviation from portfolio average. The core finding about the 20% cliff comes from here.

`vw_revenue_vs_profit_rank` ranks every customer by both revenue and profit independently, then computes the divergence between those two ranks. Customers with a large positive divergence are high-revenue, low-profit accounts, the ones that look important on a sales report but are quietly destroying margin.

`vw_subcategory_margin_trend` uses window functions to compute a 3-month rolling weighted margin per sub-category, alongside month-over-month and year-over-year delta columns. This surfaces margin erosion that snapshot views completely hide.

`vw_new_vs_returning_margin` classifies each order by whether it was placed by a new or returning customer using `ROW_NUMBER()` partitioned by customer ID. It then computes margin, average order value, and revenue per customer for each cohort.

`vw_ship_cost_as_pct_order` applies estimated shipping cost rates by ship mode and flags orders where expedited shipping was used on low-value transactions, the most common source of fulfilment-level margin leakage.

`vw_small_order_profitability` buckets orders into five size bands and applies a fixed processing cost assumption to identify where small orders are structurally unprofitable before shipping costs are even considered.

---

## EDA notebook

The Jupyter notebook in the `notebook/` folder documents the full exploratory process: dataset validation, top-line numbers, year-over-year trends, product and regional breakdowns, discount analysis, and customer behaviour. Each section ends with a written interpretation of the finding and its business implication.

The notebook is the analytical working document behind the Power BI report. It shows the questions I asked, the queries I ran, and how I arrived at the five findings before building a single visual.

### Setup

Clone the repository and navigate to the notebook folder:

```bash
git clone https://github.com/CS42-C/Superstore_Sales_Analysis.git
cd Superstore_Sales_Analysis/notebook
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Create a `.env` file using the provided example:

```bash
cp .env.example .env
```

Edit `.env` with your MySQL credentials, then open the notebook:

```bash
jupyter notebook superstore_eda.ipynb
```

The dataset is not included in this repository. Download it from Kaggle at [this link](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) and load it into a MySQL database called `portfolio` using the schema setup script in the `sql/` folder.

---

## Power BI report

The `.pbix` file in the `powerbi/` folder contains a three-page report built on a star schema with one fact table (`fact_orders`) and four dimension tables (`dim_customer`, `dim_product`, `dim_region`, `dim_date`).

The six SQL views connect to the model as standalone analytical tables and power specific visuals on the diagnostic page.

DAX measures include base aggregations, year-over-year deltas with blank guards, a weighted discount pressure index, customer rank measures using `RANKX`, rolling margin comparisons using `SAMEPERIODLASTYEAR`, and dynamic margin versus portfolio average using `ALL()` to remove filter context selectively.

The report has three pages:

The executive summary answers the central question in one screen: four KPI cards, a profit by sub-category bar chart with conditional colouring, a margin by year trend, and a margin by discount band chart. A written finding sits at the bottom tying the visuals together.

The diagnostic deep-dive has region and segment slicers that filter all four visuals simultaneously. The customer quadrant scatter plots every customer by revenue against profit, coloured by quadrant classification derived from the SQL view. The rolling margin trend line shows five selected sub-categories across four years.

The recommendations page is a written document, not a dashboard. Five findings, five actions, each with a quantified impact estimate and data pills showing the key numbers. This page exists in no other Superstore project I have seen, and it is the one that shows the difference between a business analyst and a BI developer.

---

## Tools and stack

MySQL 8.0 for data storage and analytical view creation. Window functions throughout: `RANK()`, `ROW_NUMBER()`, `LAG()`, `SUM() OVER`, `NTILE()`.

Python 3.12 with pandas, SQLAlchemy, matplotlib, and seaborn for EDA. Each finding is documented with a chart and a written interpretation.

Power BI Desktop with a properly modelled star schema. DAX measures written with explicit filter context management rather than relying on implicit aggregation.

---

## Notes on methodology

Shipping costs in `vw_ship_cost_as_pct_order` are estimated using fixed rate assumptions by ship mode since the dataset does not include actual freight cost data. The assumptions are documented in the SQL script and are intended to produce directionally valid comparisons rather than precise absolute values.

The fixed processing cost of $8 per order in `vw_small_order_profitability` is similarly an approximation. The analytical value is in the relative comparison across order size bands, not the absolute number.

Both assumptions are explicitly noted in the relevant SQL scripts and in the EDA notebook. A real-world version of this analysis would replace them with actual cost data from the ERP or logistics system.
