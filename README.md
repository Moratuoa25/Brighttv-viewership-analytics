# BrightTV Viewership Analytics

An end-to-end viewership analytics case study for BrightTV, built to help the CVM (Customer Value Management) team identify growth opportunities in the company's subscriber base.

## 🎯 Project Brief

BrightTV's CEO wants to grow the subscription base this financial year and asked for insights covering:
- User and usage trends
- What factors influence consumption
- What content could increase consumption on low-viewing days
- What initiatives could grow BrightTV's user base

## 📊 Dashboard

Built in Looker Studio, using a cleaned version of BrightTV's raw session-level viewership data (10,989 sessions, 5,375 unique viewers).

**[View the live dashboard →](#)** *(add your Looker Studio share link here)*

![Dashboard screenshot](dashboard/screenshot.png)

### What it covers
- **KPIs:** total viewing records, unique viewers, average watch duration, total watch time
- **Demographics:** gender, age group, race, and province breakdowns
- **Channel performance:** most-viewed channels vs. highest watch-time-per-session channels
- **Consumption patterns:** weekday vs. weekend, and day-of-week trends
- **Interactive filters:** gender, month, day classification, province

## 📝 Project Planning

Before building the dashboard, the project was scoped with:
- A **business requirements questions** doc — clarifying what the CVM team needed from this analysis
- A **mind map** (Miro) — mapping out the case study's four core questions and how the data would answer them
- A **Gantt chart** — planning the project timeline from EDA through to final presentation

## 🧹 Data Cleaning & SQL

All data exploration and cleaning was done in **SQL**:
- `eda_user_profile.sql` — exploratory analysis of the user/viewer profile data
- `analysis_questions.sql` — queries built to directly answer the case study's four questions
- `cte_pipeline.sql` — a CTE-based pipeline used to clean and transform the raw session data

Specific fixes made along the way:
- Null/blank values in `Gender`, `Tv_channel`, `day_name`, and `month_name` were relabeled (e.g., "Other", "Unknown") instead of showing blank
- `duration` was stored as a formatted time string (`HH:MM:SS`), not a usable number — converted to `duration_seconds` and `duration_minutes` for accurate averaging
- Verified aggregation types throughout (Record Count vs. Count Distinct) to avoid misleading KPIs

## 🔑 Key Insights

- **Gender skew:** 81.5% of viewers are male, with female and unspecified viewers together making up less than 20% — a clear growth opportunity
- **Weekday-driven consumption:** weekday viewing is more than double weekend viewing, suggesting live/appointment content (sport, news) drives usage
- **Day-of-week pattern:** consumption is lowest Monday/Tuesday and climbs steadily toward a Friday peak
- **Channel performance:** Live Events leads on both reach and watch time; ICC Cricket drives high reach with shorter average sessions; several smaller channels retain viewers longer per session than their view count suggests

## 💡 Recommendations

1. **Premiere new content Thursday/Friday** to ride the natural weekly upward momentum
2. **Use Monday/Tuesday for catch-up/rerun blocks** of top performers instead of competing with fresh releases on low-viewing days
3. **Promote long-tail channels** (Boomerang, Cartoon Network, Africa Magic) more prominently on low-consumption days
4. **Invest in content and marketing for underrepresented viewers** — women, and other age/race segments beyond the dominant "Young"/"Adult" male audience
5. **Expand beyond the top two provinces** (Gauteng, Western Cape) with regional or language-tailored content

## 🛠️ Tools Used

- **SQL** — data cleaning (null handling, field standardization)
- **Looker Studio** — dashboard build, filtering, and visualization
- **Miro** — project mind map
- **Canva** — Gantt chart / project planning visuals
- **PowerPoint** — stakeholder presentation deck

## 📁 Repo Structure

```
brighttv-viewership-analytics/
├── README.md
├── dashboard/
│   └── screenshot.png
├── presentation/
│   └── BrightTV_Viewership_Analysis.pptx
├── planning/
│   ├── business_requirements_questions.md
│   ├── mindmap_miro.png
│   └── gantt_chart.png
├── sql/
│   ├── eda_user_profile.sql
│   ├── analysis_questions.sql
│   └── cte_pipeline.sql
└── data/
    └── (raw and cleaned datasets, if shareable)
```

## 👤 Author

**Moratuoa Nthinya** — Data Analyst · AI Workflow Builder
[GitHub](https://github.com/Moratuoa25)
