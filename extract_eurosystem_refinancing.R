###Separate Eurosystem refinancing operations from ELA
###Corey Runkel


###Setup#########################
library(tidyverse)
library(lubridate)

bog_fa <- read_csv("data_out/BankOfGreece_BalanceSheet_ChangingComposition_2002-2021.csv")


###Label items###################
ela <- bog_fa %>%
  filter(column == "ASSET", line == 6 | grepl("[Ss]undry|Fine-tuning|Main|Longer-term", item),
         accounting_period > as_date("2010-03-01")) %>% #remove extraneous items
  mutate(crisis = if_else(between(accounting_period, as_date("2011-07-01"), as_date("2014-05-01")) | between(accounting_period, as_date("2015-01-01"), as_date("2019-02-01")), TRUE, FALSE),
         line = fct_relevel(case_when(line == 5 & subline == 1 ~ "MROs",
                                      line == 5 & subline == 2 ~ "LTROs",
                                      line == 5 & subline == 3 ~ "FTOs",
                                      line == 6 & crisis == TRUE & accounting_period > as_date("2012-03-15") ~ "ELA",
                                      line == 6 & (crisis == FALSE | accounting_period < as_date("2012-03-15")) ~ "Other",
                                      grepl("[Ss]undry", item) & crisis == TRUE & accounting_period < as_date("2012-04-15") ~ "ELA",
                                      grepl("[Ss]undry", item) & (crisis == FALSE | accounting_period > as_date("2012-04-15")) ~ "Sundry")))

###Plot#########################
ela %>%
  complete(accounting_period, line) %>% #make missing lines into NAs
  mutate(amount = replace_na(amount, 0)) %>% #make NAs into 0s
  filter(between(accounting_period, as_date("2011-01-01"), as_date("2019-12-31"))) %>%
  ggplot() +
  geom_area(aes(accounting_period, amount, fill = line)) +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  scale_y_continuous(labels = scales::dollar_format(scale = 1/1000000000, prefix = "€")) +
  labs(x = "Month", y = "Outstanding liquidity (billions)", fill = "Source") + #Note: The median non-ELA Sundry amount was €2.2 million and Line 6 amount was €1.5 billion.
  theme(legend.position = "bottom")