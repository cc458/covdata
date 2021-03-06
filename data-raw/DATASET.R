## code to prepare covid datasets

library(tidyverse)
library(lubridate)
library(here)
library(janitor)
library(socviz)
library(ggrepel)
library(paletteer)

## Check for data/ dir in data-raw
ifelse(!dir.exists(here("data-raw/data")),
       dir.create(file.path("data-raw/data")),
       FALSE)


### Data-getting functions
## Download today's CSV file, saving it to data/ and also read it in
get_ecdc_csv <- function(url = "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv",
                         date = lubridate::today(),
                         writedate = lubridate::today(),
                         fname = "ecdc-cumulative-",
                         ext = "csv",
                         dest = "data-raw/data",
                         save_file = c("y", "n")) {

  target <- url
  message("target: ", target)
  save_file <- match.arg(save_file)

  destination <- fs::path(here::here("data-raw/data"), paste0(fname, writedate), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)

  switch(save_file,
    y = fs::file_copy(tf, destination),
    n = NULL)

  janitor::clean_names(readr::read_csv(tf))

}


## Get Daily COVID Tracking Project Data
## form is https://covidtracking.com/api/us/daily.csv
get_uscovid_data <- function(url = "https://covidtracking.com/api/",
                             unit = c("states", "us"),
                             fname = "-",
                             date = lubridate::today(),
                             ext = "csv",
                             dest = "data-raw/data",
                             save_file = c("y", "n")) {
  unit <- match.arg(unit)
  target <-  paste0(url, unit, "/", "daily.", ext)
  message("target: ", target)

  destination <- fs::path(here::here("data-raw/data"),
                          paste0(unit, "_daily_", date), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)

  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  janitor::clean_names(read_csv(tf))
}


## Google
get_google_data <- function(url = "https://www.gstatic.com/covid19/mobility/",
                             fname = "Global_Mobility_Report",
                             date = lubridate::today(),
                             ext = "csv",
                             dest = "data-raw/data",
                             save_file = c("n", "y")) {

  save_file <- match.arg(save_file)

  target <-  paste0(url, fname, ".", ext)
  message("target: ", target)

  destination <- fs::path(here::here("data-raw/data"),
                          paste0(fname, "_", date), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)

  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  ## Need a colspec for the Google data because it's so large
  ## read_csv's guesses fail for some columns.
  gm_spec <- cols(country_region_code = col_character(),
                  country_region = col_character(),
                  sub_region_1 = col_character(),
                  sub_region_2 = col_character(),
                  date = col_date(),
                  retail_and_recreation_percent_change_from_baseline = col_integer(),
                  grocery_and_pharmacy_percent_change_from_baseline = col_integer(),
                  parks_percent_change_from_baseline = col_integer(),
                  transit_stations_percent_change_from_baseline = col_integer(),
                  workplaces_percent_change_from_baseline = col_integer(),
                  residential_percent_change_from_baseline = col_integer())


  janitor::clean_names(read_csv(tf, col_types = gm_spec))
}


## Get NYT data from their repo
get_nyt_county <- function(url = "https://github.com/nytimes/covid-19-data/raw/master/",
                           fname = "us-counties",
                           date = lubridate::today(),
                           ext = "csv",
                           dest = "data-raw/data",
                           save_file = c("n", "y")) {

  save_file <- match.arg(save_file)
  target <-  paste0(url, fname, ".", ext)
  message("target: ", target)

  destination <- fs::path(here::here("data-raw/data"),
                          paste0(fname, "_", date), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)

  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  janitor::clean_names(read_csv(tf))
  }


get_nyt_states <- function(url = "https://github.com/nytimes/covid-19-data/raw/master/",
                           fname = "us-states",
                           date = lubridate::today(),
                           ext = "csv",
                           dest = "data-raw/data",
                           save_file = c("n", "y")) {

  save_file <- match.arg(save_file)
  target <-  paste0(url, fname, ".", ext)
  message("target: ", target)

  destination <- fs::path(here::here("data-raw/data"),
                          paste0(fname, "_", date), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)

  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  janitor::clean_names(read_csv(tf))
}


get_nyt_us <- function(url = "https://github.com/nytimes/covid-19-data/raw/master/",
                           fname = "us",
                           date = lubridate::today(),
                           ext = "csv",
                           dest = "data-raw/data",
                           save_file = c("n", "y")) {

  save_file <- match.arg(save_file)
  target <-  paste0(url, fname, ".", ext)
  message("target: ", target)

  destination <- fs::path(here::here("data-raw/data"),
                          paste0(fname, "_", date), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)

  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  janitor::clean_names(read_csv(tf))
}

## Get Apple data
## 1. Find today's URL
get_apple_target <- function(cdn_url = "https://covid19-static.cdn-apple.com",
                             json_file = "covid19-mobility-data/current/v3/index.json") {
  tf <- tempfile(fileext = ".json")
  curl::curl_download(paste0(cdn_url, "/", json_file), tf)
  json_data <- jsonlite::fromJSON(tf)
  paste0(cdn_url, json_data$basePath, json_data$regions$`en-us`$csvPath)
}

## 2. Get the data and return a tibble
get_apple_data <- function(url = get_apple_target(),
                             fname = "applemobilitytrends-",
                             date = stringr::str_extract(get_apple_target(), "\\d{4}-\\d{2}-\\d{2}"),
                             ext = "csv",
                             dest = "data-raw/data",
                             save_file = c("n", "y")) {

  save_file <- match.arg(save_file)
  message("target: ", url)

  destination <- fs::path(here::here("data-raw/data"),
                          paste0("apple_mobility", "_daily_", date), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(url, tf)

  ## We don't save the file by default
  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  janitor::clean_names(readr::read_csv(tf))
}


## CoronaNet Data
## See https://github.com/saudiwin/corona_tscs
## and https://osf.io/preprints/socarxiv/jp4wk

# https://raw.githubusercontent.com/saudiwin/corona_tscs/master/data/CoronaNet/coronanet_release.csv
get_corona_tscs <- function(url = "https://raw.githubusercontent.com/saudiwin/corona_tscs/master/data/CoronaNet",
                            fname = "coronanet_release",
                            date = lubridate::today(),
                            ext = "csv",
                            dest = "data-raw/data",
                            save_file = c("n", "y")) {

  save_file <- match.arg(save_file)
  target <-  paste0(url, "/", fname, ".", ext)
  message("target: ", target)

  destination <- fs::path(here::here("data-raw/data"),
                          paste0("", date), ext = ext)

  tf <- tempfile(fileext = ext)
  curl::curl_download(target, tf)

  switch(save_file,
         y = fs::file_copy(tf, destination),
         n = NULL)

  cn_spec <- cols(country_region_code = col_character(),
                  country_region = col_character(),
                  sub_region_1 = col_character(),
                  sub_region_2 = col_character(),
                  date = col_date(),
                  retail_and_recreation_percent_change_from_baseline = col_integer(),
                  grocery_and_pharmacy_percent_change_from_baseline = col_integer(),
                  parks_percent_change_from_baseline = col_integer(),
                  transit_stations_percent_change_from_baseline = col_integer(),
                  workplaces_percent_change_from_baseline = col_integer(),
                  residential_percent_change_from_baseline = col_integer())


  janitor::clean_names(read_csv(tf))

}


### Data munging functions

## A useful function from Edward Visel, which does a thing
## with tibbles that in the past I've done variable-by-variable
## using match(), like an animal. The hardest part was
## figuring out that this operation is called a coalescing join
## https://alistaire.rbind.io/blog/coalescing-joins/
coalesce_join <- function(x, y,
                          by = NULL, suffix = c(".x", ".y"),
                          join = dplyr::full_join, ...) {
  joined <- join(x, y, by = by, suffix = suffix, ...)
  # names of desired output
  cols <- dplyr::union(names(x), names(y))

  to_coalesce <- names(joined)[!names(joined) %in% cols]
  suffix_used <- suffix[ifelse(endsWith(to_coalesce, suffix[1]), 1, 2)]
  # remove suffixes and deduplicate
  to_coalesce <- unique(substr(
    to_coalesce,
    1,
    nchar(to_coalesce) - nchar(suffix_used)
  ))

  coalesced <- purrr::map_dfc(to_coalesce, ~dplyr::coalesce(
    joined[[paste0(.x, suffix[1])]],
    joined[[paste0(.x, suffix[2])]]
  ))
  names(coalesced) <- to_coalesce

  dplyr::bind_cols(joined, coalesced)[cols]
}

### Country Codes

## ----iso-country-codes-------------------------------------------------------------------------------------------
## Country codes. The ECDC does not quite use standard codes for countries
## These are the iso2 and iso3 codes, plus some convenient groupings for
## possible use later
iso3_cnames <- read_csv("data-raw/data/countries_iso3.csv")
iso2_to_iso3 <- read_csv("data-raw/data/iso2_to_iso3.csv")

cname_table <- left_join(iso3_cnames, iso2_to_iso3)

cname_table

eu <- c("AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN", "FRA",
        "DEU", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "LUX", "MLT", "NLD",
        "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE", "GBR")

europe <- c("ALB", "AND", "AUT", "BLR", "BEL", "BIH", "BGR", "HRV", "CYP", "CZE",
            "DNK", "EST", "FRO", "FIN", "FRA", "DEU", "GIB", "GRC", "HUN", "ISL",
            "IRL", "ITA", "LVA", "LIE", "LTU", "LUX", "MKD", "MLT", "MDA", "MCO",
            "NLD", "NOR", "POL", "PRT", "ROU", "RUS", "SMR", "SRB", "SVK", "SVN",
            "ESP", "SWE", "CHE", "UKR", "GBR", "VAT", "RSB", "IMN", "MNE")

north_america <- c("AIA", "ATG", "ABW", "BHS", "BRB", "BLZ", "BMU", "VGB", "CAN", "CYM",
                   "CRI", "CUB", "CUW", "DMA", "DOM", "SLV", "GRL", "GRD", "GLP", "GTM",
                   "HTI", "HND", "JAM", "MTQ", "MEX", "SPM", "MSR", "ANT", "KNA", "NIC",
                   "PAN", "PRI", "KNA", "LCA", "SPM", "VCT", "TTO", "TCA", "VIR", "USA",
                   "SXM")

south_america <- c("ARG", "BOL", "BRA", "CHL", "COL", "ECU", "FLK", "GUF", "GUY", "PRY",
                   "PER", "SUR", "URY", "VEN")


africa <- c("DZA", "AGO", "SHN", "BEN", "BWA", "BFA", "BDI", "CMR", "CPV", "CAF",
            "TCD", "COM", "COG", "DJI", "EGY", "GNQ", "ERI", "ETH", "GAB", "GMB",
            "GHA", "GNB", "GIN", "CIV", "KEN", "LSO", "LBR", "LBY", "MDG", "MWI",
            "MLI", "MRT", "MUS", "MYT", "MAR", "MOZ", "NAM", "NER", "NGA", "STP",
            "REU", "RWA", "STP", "SEN", "SYC", "SLE", "SOM", "ZAF", "SHN", "SDN",
            "SWZ", "TZA", "TGO", "TUN", "UGA", "COD", "ZMB", "TZA", "ZWE", "SSD",
            "COD")

asia <- c("AFG", "ARM", "AZE", "BHR", "BGD", "BTN", "BRN", "KHM", "CHN", "CXR",
          "CCK", "IOT", "GEO", "HKG", "IND", "IDN", "IRN", "IRQ", "ISR", "JPN",
          "JOR", "KAZ", "PRK", "KOR", "KWT", "KGZ", "LAO", "LBN", "MAC", "MYS",
          "MDV", "MNG", "MMR", "NPL", "OMN", "PAK", "PHL", "QAT", "SAU", "SGP",
          "LKA", "SYR", "TWN", "TJK", "THA", "TUR", "TKM", "ARE", "UZB", "VNM",
          "YEM", "PSE")

oceania <- c("ASM", "AUS", "NZL", "COK", "FJI", "PYF", "GUM", "KIR", "MNP", "MHL",
             "FSM", "UMI", "NRU", "NCL", "NZL", "NIU", "NFK", "PLW", "PNG", "MNP",
             "SLB", "TKL", "TON", "TUV", "VUT", "UMI", "WLF", "WSM", "TLS")


### Get and clean cross-national data
covid_raw <- get_ecdc_csv(save = "n")

covid_raw

covid <- covid_raw %>%
  mutate(date = lubridate::dmy(date_rep),
         iso2 = geo_id)

## merge in the iso country names
covid <- left_join(covid, cname_table)

## A few ECDC country codes are non-iso, notably the UK
anti_join(covid, cname_table) %>%
  select(geo_id, countries_and_territories, iso2, iso3, cname) %>%
  distinct()

## A small crosswalk file that we'll coalesce into the missing values
## We need to specify the na explicity because the xwalk file has Namibia
## as a country -- i.e. country code = string literal "NA"
cname_xwalk <- read_csv("data-raw/data/ecdc_to_iso2_xwalk.csv",
                        na = "")

cname_xwalk

covid <- coalesce_join(covid, cname_xwalk,
                       by = "geo_id", join = dplyr::left_join)

## Take a look again
anti_join(covid, cname_table) %>%
  select(geo_id, countries_and_territories, iso2, iso3, cname) %>%
  distinct()

covnat <- covid %>%
  select(date, cname, iso3, cases, deaths, pop_data2018) %>%
  rename(pop_2018 = pop_data2018) %>%
  drop_na(iso3) %>%
  group_by(iso3) %>%
  arrange(date) %>%
  mutate(cu_cases = cumsum(cases),
         cu_deaths = cumsum(deaths))

covnat ## Data object


countries <- covnat %>%
  distinct(cname, iso3) %>%
  left_join(cname_table)

### Get US Data from the COVID Tracking Project
## US state data
cov_us_raw <- get_uscovid_data(url = "https://covidtracking.com/api/v1/", save_file = "n")

covus <- cov_us_raw %>%
  mutate(date = lubridate::ymd(date)) %>%
  select(!data_quality_grade:date_checked) %>%
  select(date, state, fips, everything()) %>%
  pivot_longer(positive:total_test_results_increase,
               names_to = "measure", values_to = "count") %>%
  filter(measure %nin% c("pos_neg", "total"))

covus

### Get US county data from the NYT

## NYT county data
nytcovcounty <- get_nyt_county()

### NYT state data
nytcovstate <- get_nyt_states()

### NYt national (US only) data
nytcovus <- get_nyt_us()

##


my_pdc <-  function ()
{

  res <- jsonlite::fromJSON("https://data.cdc.gov/resource/hc4f-j6nb.json")
  res <- as_tibble(res)
  res$covid_deaths <- cdccovidview:::clean_int(res$covid_deaths)
  res$total_deaths <- cdccovidview:::clean_int(res$total_deaths)
  res$percent_expected_deaths <- cdccovidview:::clean_num(res$percent_expected_deaths)
  res$pneumonia_deaths <- cdccovidview:::clean_int(res$pneumonia_deaths)
  res$pneumonia_and_covid_deaths <- cdccovidview:::clean_int(res$pneumonia_and_covid_deaths)
  res$all_influenza_deaths_j09_j11 <-cdccovidview::: clean_int(res$all_influenza_deaths_j09_j11)
  res$pneumonia_influenza_and_covid_19_deaths <- cdccovidview:::clean_int(res$pneumonia_influenza_and_covid_19_deaths)

  by_week <- res[res$group == "By week", ]
  by_age <- res[res$group == "By age", ]
  by_state <- res[res$group == "By state", ]
  by_sex <- res[res$group == "By sex", ]

  by_week <- by_week[!grepl("total", tolower(by_week$indicator)), ]
  by_week$group <- NULL
  by_week$indicator <- NULL
  by_week$footnote <- NULL
  by_week$state <- NULL
  by_week$start_week <- as.Date(by_week$start_week)
  by_week$end_week <- as.Date(by_week$end_week)
  by_week$data_as_of <- as.Date(by_week$data_as_of)
  colnames(by_week) <- c("data_as_of", "start_week", "end_week", "covid_deaths", "total_deaths",
                         "percent_expected_deaths", "pneumonia_deaths", "pneumonia_and_covid_deaths",
                         "all_influenza_deaths_j09_j11", "pneumonia_influenza_and_covid_19_deaths",
                         "pneumonia_influenza_and_covid_deaths")

  by_age$group <- NULL
  by_age$footnote <- NULL
  by_age$state <- NULL
  by_age$pneumonia_influenza_and_covid_19_deaths <- NULL

  colnames(by_age) <- c("data_as_of", "age_group", "start_week", "end_week", "covid_deaths", "total_deaths",
                        "percent_expected_deaths", "pneumonia_deaths", "pneumonia_and_covid_deaths",
                        "all_influenza_deaths_j09_j11",
                        "pneumonia_influenza_and_covid_deaths")
  by_age$age_group <- sub("&ndash;", "-", by_age$age_group,
                          fixed = TRUE)
  by_age$age_group <- sub("yea.*", "yr", by_age$age_group)
  by_age$data_as_of <- as.Date(by_age$data_as_of)
  by_age$start_week <- as.Date(by_age$start_week)
  by_age$end_week <- as.Date(by_age$end_week)


  by_state$group <- NULL
  by_state$footnote <- NULL
  by_state$indicator <- NULL
  by_state$pneumonia_influenza_and_covid_19_deaths <- NULL

  by_state$data_as_of <- as.Date(by_state$data_as_of)
  by_state$start_week <- as.Date(by_state$start_week)
  by_state$end_week <- as.Date(by_state$end_week)
  colnames(by_state) <- c("data_as_of", "state", "start_week", "end_week", "covid_deaths", "total_deaths",
                          "percent_expected_deaths", "pneumonia_deaths", "pneumonia_and_covid_deaths",
                          "all_influenza_deaths_j09_j11",
                          "pneumonia_influenza_and_covid_deaths")
  by_state <- by_state[by_state$state != "United States", ]


  by_sex$group <- NULL
  by_sex$footnote <- NULL
  by_sex$state <- NULL
  by_sex$pneumonia_influenza_and_covid_19_deaths <- NULL

  by_sex$data_as_of <- as.Date(by_sex$data_as_of)
  by_sex$start_week <- as.Date(by_sex$start_week)
  by_sex$end_week <- as.Date(by_sex$end_week)


  colnames(by_sex) <- c("data_as_of", "sex", "start_week", "end_week", "covid_deaths", "total_deaths",
                        "percent_expected_deaths", "pneumonia_deaths", "pneumonia_and_covid_deaths",
                        "all_influenza_deaths_j09_j11",
                        "pneumonia_influenza_and_covid_deaths")

  by_sex <- by_sex[!grepl("Total deaths", by_sex$sex), ]
  list(by_week = as_tibble(by_week), by_age = as_tibble(by_age),
       by_state = as_tibble(by_state), by_sex = as_tibble(by_sex))
}



## Get CDC Surveillance Data
## Courtesy of Bob Rudis's cdccovidview package
cdc_hospitalizations <- cdccovidview::laboratory_confirmed_hospitalizations()

## cdc_death_counts <- cdccovidview::provisional_death_counts()
cdc_death_counts <- my_pdc()

cdc_deaths_by_week <- cdc_death_counts$by_week
cdc_deaths_by_age <- cdc_death_counts$by_age
cdc_deaths_by_sex <- cdc_death_counts$by_sex
cdc_deaths_by_state <- cdc_death_counts$by_state

cdc_catchments <- cdccovidview::surveillance_areas()

nssp_covid_er_nat <- cdccovidview::nssp_er_visits_national()
nssp_covid_er_reg <- cdccovidview::nssp_er_visits_regional()

## Apple Mobility Data
apple_mobility <- get_apple_data() %>%
  pivot_longer(cols = starts_with("x"), names_to = "date", values_to = "index") %>%
  mutate(
    date = stringr::str_remove(date, "x"),
    date = stringr::str_replace_all(date, "_", "-"),
    date = as_date(date))

## Google Mobility Data

google_mobility <- get_google_data() %>%
  rename(retail = retail_and_recreation_percent_change_from_baseline,
         grocery = grocery_and_pharmacy_percent_change_from_baseline,
         parks = parks_percent_change_from_baseline,
         transit = transit_stations_percent_change_from_baseline,
         workplaces = workplaces_percent_change_from_baseline,
         residential = residential_percent_change_from_baseline) %>%
  pivot_longer(retail:residential, names_to = "type", values_to = "pct_diff")



## CoronaNet
coronanet_raw <- get_corona_tscs()

## Seems like everything is missing on `link_type`?
coronanet_raw %>%
  slice(problems(coronanet_raw)$row) %>%
  select(record_id, entry_type, link, link_type) %>%
  print(n = 50)

cnet_vars <- c("record_id", "policy_id", "recorded_date", "date_announced", "date_start", "date_end",
               "entry_type", "event_description", "domestic_policy", "type", "type_sub_cat",
               "type_text", "index_high_est", "index_med_est", "index_low_est", "index_country_rank",
               "country", "init_country_level", "province", "target_country", "target_geog_level",
               "target_region", "target_province", "target_city", "target_other", "target_who_what",
               "target_direction", "travel_mechanism", "compliance", "enforcer", "link", "iso_a3", "iso_a2")

coronanet <- coronanet_raw %>%
  select(cnet_vars) %>%
  rename(iso3 = iso_a3, iso2 = iso_a2)

## Write data

## ECDC
usethis::use_data(covnat, overwrite = TRUE, compress = "xz")

## COVID Tracking Project
usethis::use_data(covus, overwrite = TRUE, compress = "xz")

## NYT
usethis::use_data(nytcovcounty, overwrite = TRUE, compress = "xz")
usethis::use_data(nytcovstate, overwrite = TRUE, compress = "xz")
usethis::use_data(nytcovus, overwrite = TRUE, compress = "xz")

## Country codes
usethis::use_data(countries, overwrite = TRUE, compress = "xz")

## CDC surveillance
usethis::use_data(cdc_hospitalizations, overwrite = TRUE, compress = "xz")
usethis::use_data(cdc_deaths_by_week, overwrite = TRUE, compress = "xz")
usethis::use_data(cdc_deaths_by_age, overwrite = TRUE, compress = "xz")
usethis::use_data(cdc_deaths_by_sex, overwrite = TRUE, compress = "xz")
usethis::use_data(cdc_deaths_by_state, overwrite = TRUE, compress = "xz")
usethis::use_data(cdc_catchments, overwrite = TRUE, compress = "xz")
usethis::use_data(nssp_covid_er_nat, overwrite = TRUE, compress = "xz")
usethis::use_data(nssp_covid_er_reg, overwrite = TRUE, compress = "xz")

## Apple and Google
usethis::use_data(apple_mobility, overwrite = TRUE, compress = "xz")
usethis::use_data(google_mobility, overwrite = TRUE, compress = "xz")

## CoronaNet
usethis::use_data(coronanet, overwrite = TRUE, compress = "xz")

document()
knit("README.Rmd")
