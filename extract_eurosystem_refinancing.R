###Separate Eurosystem refinancing operations from ELA
###Corey Runkel


###Setup############################################
library(tidyverse)
library(lubridate)

`%out%` <- Negate(`%in%`)

bog_fa <- read_csv("BankOfGreece_MonthlyBalanceSheet_Aug2009-Apr2019.csv")


###Combine sundry items and Line 6##################
ela <- bog_fa %>%
  filter(column == "ASSET", line == 6 | grepl("[Ss]undry|Fine-tuning|Main|Longer-term", item), between(month, as_date("2010-03-01"), as_date("2019-03-01"))) %>% #remove extraneous items
  mutate(crisis = if_else(between(month, as_date("2011-07-01"), as_date("2014-05-01")) | between(month, as_date("2015-01-01"), as_date("2019-02-01")), TRUE, FALSE),
         line = fct_relevel(case_when(line == 5 & subline == 1 ~ "MROs",
                                      line == 5 & subline == 2 ~ "LTROs",
                                      line == 5 & subline == 3 ~ "FTOs",
                                      line == 6 & crisis == TRUE & month > as_date("2012-03-15") ~ "ELA",
                                      line == 6 & (crisis == FALSE | month < as_date("2012-03-15")) ~ "Other",
                                      line == 10 & crisis == TRUE & month < as_date("2012-03-15") ~ "ELA",
                                      line == 10 & (crisis == FALSE | month > as_date("2012-03-15")) ~ "Sundry"))) %>% #rename
  group_by(month, line) %>%
  summarize(amount = sum(amount)) %>%
  ungroup()

###Estimate ELA portion (not ready yet)#############
#ela <- ela %>%
#  group_by(line) %>%
#  complete(month = seq.Date(as_date("2011-08-01"), as_date("2019-04-01"), by = "month")) %>%
#  ungroup() %>%
#  filter(month %out% seq.Date(as_date("2011-12-01"), as_date("2018-12-01"), by = "year")) %>%
#  mutate(amount = if_else(is.na(amount), median(ela$amount[ela$line == "Other" & ela$crisis == TRUE]), amount))

###Plot#############################################
ggplot(ela) +
  geom_col(aes(month, amount, fill = line)) +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  scale_y_continuous(labels = scales::dollar_format(scale = 1/1000000000, prefix = "€")) +
  labs(x = "Month", y = "Outstanding liquidity (billions)", title = "Outstanding liquidity from the Bank of Greece to Eurosystem credit institutions", fill = "Type")