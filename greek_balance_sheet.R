#' Fetch and tabularize Bank of Greece monthly financial statements
#'
#' @param accounting_period An object coercible to a date no earlier than
#' 2002-01-01, or a two-object vector specifying start and end dates.
#' @param composition One of "changing" or "constant".
#' @return A tibble representing one or more tidy balance sheets.
#' @examples
#' greek_balance_sheet(c("2011-08-01", "2012-12-01"), "changing")
#' @details Does not include December 2002, March 2003, or August 2003
#' due to their structures. Constant composition removes subline items
#' and relabels lines to account for the Items in settlement line in December
#' accounts.

greek_balance_sheet <- function(accounting_period = Sys.Date()-50,
                              composition = c("changing", "constant")) {
  ###Setup#############################################
  #depends
  #library(pdftools)
  #library(tidyverse)
  #library(lubridate)

  #components
  if (length(accounting_period)<2) {
    accounting_period <- as_date(accounting_period)
    file_url <- paste0("https://www.bankofgreece.gr/Publications/", #base URL
                       ifelse(month(accounting_period) == 12, #annual accounts
                              paste0("isol",
                                     year(accounting_period)),
                              paste0("financialstat", #monthly accounts
                                     format(accounting_period,
                                            "%Y%m"),
                                     "_en")),
                       ".pdf")

    #text parsing
    bal_sheet_matrix <- pdf_data(file(file_url))[[1]]


    ###Reassemble table##################################
    bal_sheet <- bal_sheet_matrix %>%
      mutate(accounting_period = ceiling_date(accounting_period, unit = "month") - 1,
             #restrict to on-balance-sheet entries
             column = ifelse(x < x[grepl("euro", text, ignore.case = FALSE)][[1]], "ASSET", "LIABILITY")) %>%
      arrange(x) %>%
      group_by(accounting_period, column, y) %>%
      summarize(item = paste0(text, ifelse(space, " ", ""), collapse = ""), .groups = "drop") %>%
      filter(y >= y[grepl("Gold", item)][[1]], #approximate upper bound of balance sheet...
             y < (y[grepl("TOTAL|T O T A", item)][[1]] - 10)) %>% #...and lower bound
      #collapse rows if row does not begin/end with number
      mutate(item = ifelse(grepl("^[0-9]", item), item, paste(dplyr::lag(item, 1), item))) %>%
      ungroup() %>%
      select(-y) %>%
      filter(grepl("[0-9]$", item)) %>%
      #separate line from subline from item from amount
      extract(item,
              c("line", "subline", "item", "amount"),
              "^([0-9]+)\\.([0-9]?)(.+[^\\d\\.,])([0-9|,|\\.]+)$") %>%
      #remove previous year amounts from annual accounts
      mutate(amount = as.numeric(str_remove_all(case_when(month(accounting_period) != 12 ~ amount,
                                                          grepl("^0.+", amount) ~ "0",
                                                          grepl("[0-9]{4,6}", amount) ~ gsub("^(.+)[,\\.]([0-9]{3})([0-9]{1,3})(.*)$", "\\1\\2", amount),
                                                          TRUE ~ amount), ",|\\.")),
             subline = na_if(subline, ""),
             item = str_trim(item, side = "both"))


    ###Adjust for composition############################
    if (composition == "changing") {
      #remove total lines if there exist sublines
      bal_sheet <- bal_sheet %>%
        group_by(column, line) %>%
        filter(n() == 1 | !is.na(subline)) %>%
        ungroup() %>%
        mutate_at(c("column", "line", "subline"), as_factor)
    }

    else {
      #remove sublines
      bal_sheet <- bal_sheet %>%
        filter(is.na(subline)) %>%
        select(-subline) %>%
        mutate(column = as_factor(column),
               line = as.numeric(line),
               line = as_factor(ifelse(month(accounting_period) != 12 & line > 9, line+1, line)))
    }


    return(bal_sheet)
  }


  else {
    ###Setup############################################
    accounting_periods <- seq.Date(floor_date(as_date(accounting_period[[1]]), unit = "month"), floor_date(as_date(accounting_period[[2]]), unit = "month"), by = "month")


    ###Function#########################################
    map_df(accounting_periods[!grepl("2002\\-12|2002\\-11\\-01|2003\\-0(5|8)\\-01", accounting_periods)], ~ greek_balance_sheet(.x, composition = composition)) %>%
      return()
  }
}