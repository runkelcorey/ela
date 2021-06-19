###Compile ELA data
###Corey Runkel

###Setup#############################
library(tidyverse)
library(pdftools)
library(lubridate)


###Changing composition##############
#base case
bog_fa_changing <- get_balance_sheet("2002-01-01", "changing") %>%
  mutate(month = as_date("2002-01-01"))

#setup loop (can be done w/ function but will probably time out)
months <- seq.Date(as_date("2002-02-01"), floor_date(Sys.Date()-30, unit = "month"), "month")
for (i in months[!grepl("\\-12\\-|2002\\-11\\-01|2003\\-0[58]\\-01", months)]) {
  bog_fa_changing <- bog_fa_changing %>%
#get balance sheet
  bind_rows(mutate(get_balance_sheet(i, "changing"), month = as_date(i)))
}


###Constant composition##############
#base case
bog_fa_constant <- get_balance_sheet("2002-01-01", "constant") %>%
  mutate(month = as_date("2002-01-01"))

#setup loop (can be done w/ function but will probably time out)
for (i in months[!grepl("\\-12\\-|2002\\-11\\-01|2003\\-0[58]\\-01", months)]) {
  bog_fa_constant <- bog_fa_constant %>%
    #get balance sheet
    bind_rows(mutate(get_balance_sheet(i, "constant"), month = as_date(i)))
}