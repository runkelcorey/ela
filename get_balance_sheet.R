###Fetch and tabularize Bank of Greece PDF financial statements
###Corey Runkel

get_balance_sheet <- function(nearest_date = NULL) {
###Setup#############################################
#libraries
#library(pdftools)
#library(tidyverse)
#library(lubridate)

#components
file_url <- paste0("https://www.bankofgreece.gr/Publications/financialstat", str_remove(str_sub(floor_date(as_date(nearest_date), unit = "month"), end = 7), pattern = "-"), "_en.pdf")

#table
bal_sheet_matrix <- pdf_data(file(file_url))[[1]]


###Assign properties##################################
#restrict to assets/liabilities
bal_sheet <- bal_sheet_matrix %>%
  filter(y > 170, y < (bal_sheet_matrix$y[grepl("BALANCE", bal_sheet_matrix$text, ignore.case = FALSE)] - 30)) %>% #restrict to balance sheet
  mutate(column = if_else(x < 600, "ASSET", "LIABILITY")) %>%
  arrange(x)

#reconnect lines (group_by and summarize should work but do not!!!)
bal_sheet <- aggregate(bal_sheet$text, list(column = bal_sheet$column, y = bal_sheet$y), paste, collapse = " ") %>%
  rename(item = x)

#collapse rows if row does not begin/end with number
bal_sheet <- bal_sheet %>%
  group_by(column) %>%
  mutate(item = if_else(grepl("^[0-9]", item), item, paste(dplyr::lag(item, 1), item))) %>%
  ungroup() %>%
  filter(grepl("[0-9]$", item))

#separate by row number, text, total
bal_sheet <- bal_sheet %>%
  separate(item, sep = " ", into = c("line", "item"), extra = "merge") %>%
  select(-y) %>%
  separate(line, sep = "\\.", into = c("line", "subline"), fill = "right") %>%
  mutate(amount = str_trim(str_extract(str_remove_all(item, ","), " [0-9]+")),
         item = str_trim(str_remove_all(item, "[0-9]|,")),
         column = as_factor(column))

#remove total rows if there exist subsidiary rows
bal_sheet <- bal_sheet %>%
  group_by(column, line) %>%
  add_count() %>%
  ungroup() %>%
  mutate_at(c("line", "subline", "amount"), as.numeric) %>%
  filter(n == 1 | subline > 0, !grepl("TOTAL|ASSETS|LIABILITIES", item), !is.na(line)) %>%
  select(-n)


return(bal_sheet)
}