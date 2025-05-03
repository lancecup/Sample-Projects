# Spatial Inequality in the United Kingdom: A Multivariate Analysis

This project explores spatial inequality across towns in the United Kingdom using a combination of factor analysis, hierarchical clustering, and multivariate generalized linear models. Drawing from a rich dataset on housing, demographics, and socioeconomic indicators, it seeks to understand how regional disparities manifest and what latent structures explain differences in affordability, vulnerability, and wealth.

## Overview

Main Questions:
1. What latent factors underlie structural differences across towns in the UK?
2. Can towns be meaningfully clustered based on socioeconomic and housing characteristics?
3. How do socioeconomic conditions predict housing outcomes like prices and homeownership?

## Methods Used

- Factor Analysis: Reduced 10 socioeconomic indicators to two orthogonal latent factors:
  - Affluence–Vulnerability Gradient
  - Housing Transiency
- Hierarchical Clustering: Identified six town clusters including London, elite university cities, commuter belts, and post-industrial towns.
- Multivariate GLM: Assessed how factors like commuting, education, health, and region jointly predict house prices and homeownership rates.

## Dataset

The analysis uses the 2016 Housing and Commuting dataset by Prothero (ONS), built from:
- 2011 Census
- 2015 Index of Multiple Deprivation (IMD)
- Land Registry data (2004–2015)

Key Variables:
- Median house price
- Health vulnerability
- Educational attainment
- Commuting flows
- Housing tenure (ownership vs rental)
- Manufacturing employment
- Crime ranking

## Key Findings

- Factor Analysis revealed two main dimensions driving spatial inequality:
  - Economic prosperity vs marginalization
  - Stability vs transiency in housing
- Clustering identified distinct regional town profiles:
  - London (outlier)
  - Elite university towns (e.g., Oxford, Cambridge)
  - Affluent commuter belts
  - Regional service hubs
  - Post-industrial towns
  - Mid-tier stable settlements
- Multivariate GLM found that:
  - Commuting patterns, health, and education significantly predict housing outcomes
  - London stands out with far higher prices and lower homeownership
  - Income deprivation and house price growth alone were not statistically significant

## Policy Implications

- Post-industrial towns: Invest in education and health to support economic transition
- University towns & commuter belts: Expand affordable housing supply
- London: Requires large-scale solutions recognizing its national economic pull

## Files

- MultivariateFinal.Rmd – R Markdown script with full analysis and code
- S_DS_363_Final.pdf – Final report describing methodology, findings, and implications

## References

- Piketty, T. (2014). Capital in the Twenty-First Century. Harvard University Press.
- Prothero, R. (2016). ONS Housing and Commuting Dataset.
- Yang & Pan (2020). Human Capital and Regional Development. Cities, 98:102577.
