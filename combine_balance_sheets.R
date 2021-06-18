###Compile ELA data
###Corey Runkel

###Setup#############################
library(tidyverse)
library(pdftools)
library(lubridate)

###Combine financial statements######
#base case
bog_fa <- get_balance_sheet("2009-08-01") %>%
  mutate(month = as_date("2009-08-01"))

#setup loop (can be done w/ function but will probably time out)
months <- seq.Date(as_date("2009-12-01"), as_date("2019-04-01"), "month")
for (i in months[!grepl("\\-12\\-", months)]) {
  bog_fa <- bog_fa %>%
#get balance sheet
  bind_rows(mutate(get_balance_sheet(i), month = as_date(i)))
}