###Fetch and tabularize Bank of Greece PDF financial statements
###Corey Runkel

get_balance_sheet <- function(month = Sys.Date()-30, composition = c("changing", "constant")) {
###Setup#############################################
#depends
#library(pdftools)
#library(tidyverse)
#library(lubridate)

#components
file_url <- paste0("https://www.bankofgreece.gr/Publications/financialstat", #base URL
                   str_remove(str_sub(floor_date(as_date(month), unit = "month"), end = 7), pattern = "-"), #comprehensible dates
                   "_en.pdf") #more base URL

#text parsing
bal_sheet_matrix <- pdf_data(file(file_url))[[1]]


###Reassemble table##################################
#restrict to on-balance-sheet entries
bal_sheet <- bal_sheet_matrix %>%
  filter(y > (bal_sheet_matrix$y[grepl("ASSETS", bal_sheet_matrix$text, ignore.case = FALSE)][[1]] + 10), #approximate upper bound of balance sheet...
         y < (bal_sheet_matrix$y[grepl("TOTAL", bal_sheet_matrix$text, ignore.case = FALSE)][[1]] - 10)) %>% #...and lower bound
  mutate(column = ifelse(x < 600, "ASSET", "LIABILITY")) %>%
  arrange(x) %>% #order text correctly
#re-unify rows within assets and liabilities
  group_by(column, y) %>%
  summarize(item = paste(text, collapse = " ")) %>%
#collapse rows if row does not begin/end with number
  mutate(item = ifelse(grepl("^[0-9]", item), item, paste(dplyr::lag(item, 1), item))) %>%
  ungroup() %>%
  select(-y) %>%
  filter(grepl("[0-9]$", item)) %>%
#separate line from subline from item from amount
  extract(item, c("line", "subline", "item", "amount"), "(^[0-9]+)\\.([0-9]?) (.+) ([0-9|,|\\.]+)", convert = TRUE)


###Adjust for composition############################
if (composition == "changing") {
  #remove total lines if there exist sublines
  bal_sheet <- bal_sheet %>%
    group_by(column, line) %>%
    filter(n() == 1 | !is.na(subline)) %>%
    ungroup() %>%
    mutate(amount = as.numeric(str_remove_all(amount, ",|\\."))) %>%
    mutate_at(c("column", "line", "subline"), as_factor)
}

else {
  #remove sublines
  bal_sheet <- bal_sheet %>%
    filter(is.na(subline)) %>%
    select(column, line, amount) %>%
    mutate(amount = as.numeric(str_remove_all(amount, ",|\\."))) %>%
    mutate_at(c("column", "line"), as_factor)
}


return(bal_sheet)
}