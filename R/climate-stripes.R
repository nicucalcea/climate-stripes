library(tidyverse)
library(rvest)
library(countrycode)
library(samizdata)
library(shadowtext)

##----------------------------------------------------------------
##                          Berkley data                         -
##----------------------------------------------------------------

berkeley_countries <- rvest::read_html(
    "https://berkeleyearth.org/temperature-country-list/"
) |>
    html_element("table") |>
    html_table() |>
    mutate(iso3c = countrycode(Country, "country.name", "iso3c")) |>
    filter(iso3c %in% na.omit(ee_countries("iso3c")))

get_berkeley <- function(country) {
    print(country)

    slug <- stringr::str_to_lower(country) |>
        stringr::str_replace_all(" ", "-")

    berkeley_page <- read_lines(paste0(
        "https://berkeley-earth-temperature.s3.us-west-1.amazonaws.com/Regional/TAVG/",
        slug,
        "-TAVG-Trend.txt"
    ))

    berkeley_baseline_index <- grep(
        "Estimated Jan 1951-Dec 1980 monthly absolute temperature \\(C\\):",
        berkeley_page
    )

    berkeley_baseline <- berkeley_page[berkeley_baseline_index + 2] |>
        str_remove("^%%\\s*") |>
        str_remove("^%\\s*") |>
        str_trim() |>
        str_split("\\s+") |>
        unlist() |>
        as.numeric()

    berkeley_baseline <- tibble(
        month = 1:12,
        temp_baseline = berkeley_baseline
    )

    berkeley <- read_table(
        berkeley_page,
        skip = 71, # Skip the comment lines
        col_names = c(
            "year",
            "month",
            "Monthly_Anomaly",
            "Monthly_Unc",
            "Annual_Anomaly",
            "Annual_Unc",
            "Five_year_Anomaly",
            "Five_year_Unc",
            "Ten_year_Anomaly",
            "Ten_year_Unc",
            "Twenty_year_Anomaly",
            "Twenty_year_Unc"
        ),
        na = "NaN"
    ) |>
        mutate(
            across(where(is.character), ~ na_if(.x, "NaN")),
            across(-c(year, month), as.numeric),
            date = as.Date(paste0(year, "-", month, "-01"))
        ) |>
        left_join(berkeley_baseline, by = "month") |>
        mutate(
            country = country,
            temp = Monthly_Anomaly + temp_baseline,
            source = "Berkeley Earth"
        ) |>
        select(country, date, temp, source)

    return(berkeley)
}

berkeley <- map(
    berkeley_countries$Country,
    get_berkeley
) |>
    bind_rows()


## ---------------------------------------------------------------
##                          OWID data                           -
## ---------------------------------------------------------------

owid <- read_csv(
    "https://ourworldindata.org/grapher/monthly-average-surface-temperatures-by-year.csv"
) |>
    filter(Code %in% c(na.omit(ee_countries("iso3c")), "OWID_KOS")) |>
    rename(month = Year) |>
    group_by(Entity) |>
    pivot_longer(
        cols = -c(Entity, Code, month),
        names_to = "year",
        values_to = "Temperature"
    ) |>
    # filter(Entity == "Moldova") |>
    mutate(
        date = as.Date(paste0(year, "-", month, "-01")),
        year = floor_date(
            date,
            "year"
        ),
        source = "Our World in Data"
    ) |>
    drop_na(Temperature) |>
    arrange(date) |>
    select(country = Entity, iso3c = Code, date, temp = Temperature, source)


## ----------------------------------------------------------------
##                        Combine datasets                       -
## ----------------------------------------------------------------

temps <- berkeley |>
    mutate(iso3c = countrycode(country, "country.name", "iso3c")) |>
    bind_rows(owid) |>
    drop_na(temp) |>
    mutate(
        country = countrycode(
            iso3c,
            "iso3c",
            "country.name",
            custom_match = c(
                "OWID_KOS" = "Kosovo"
            )
        )
    ) |>
    arrange(iso3c, date, source) |>
    distinct(iso3c, date, .keep_all = TRUE)

temps_year <- temps |>
    group_by(country, iso3c, date = floor_date(date, "year")) |>
    summarise(
        temp = mean(temp, na.rm = TRUE),
        count = n()
    ) |>
    ungroup() |>
    filter(count == 12)

## ----------------------------------------------------------------
##                            Themeing                           -
## ----------------------------------------------------------------

col_strip <- samizcolour(c(
    "red_100",
    "red_90",
    "red_80",
    "red_70",
    "red_60",
    "red_50",
    "red_40",
    "red_30",
    "red_20",
    "red_10",
    "warm_gray_20",
    "blue_10",
    "blue_20",
    "blue_30",
    "blue_40",
    "blue_50",
    "blue_60",
    "blue_70",
    "blue_80",
    "blue_90",
    "blue_100"
))

## ---------------------------------------------------------------
##                  Chart generation function                   -
## ---------------------------------------------------------------

create_chart <- function(temps_year, selected_country) {
    slug = stringr::str_to_lower(selected_country) |>
        stringr::str_replace_all(" ", "-")

    path = paste0("publish/", slug, "/")

    # create folder if it doesn't exist
    if (!dir.exists(path)) {
        dir.create(path, recursive = TRUE)
    }

    temps_country <- temps_year |>
        filter(country == selected_country) |>
        # rescale temp to 0.5 to 1.5
        mutate(
            temp_line = scales::rescale(temp, to = c(0.59, 1.41)),
            temp_line_rolling = zoo::rollmean(temp, k = 10, fill = NA),
            temp_line_rolling = scales::rescale(
                temp_line_rolling,
                to = c(0.59, 1.41)
            )
        )

    maxmin <- range(temps_country$temp, na.rm = T)
    mean <- mean(temps_country$temp, na.rm = T)

    # no labels charts
    temps_chart <- temps_country |>
        ggplot(aes(x = date, y = 1, fill = temp)) +
        geom_tile() +
        scale_fill_gradientn(
            colors = rev(col_strip),
            values = scales::rescale(c(maxmin[1], mean, maxmin[2])),
            na.value = "gray80"
        ) +
        labs(
            caption = paste0(
                "Annual temperature in ",
                selected_country,
                " (",
                year(min(temps_country$date)),
                "—",
                year(max(temps_country$date)),
                ") • Sources: Berkeley Earth, Copernicus Climate Change Service (via Our World in Data)"
            )
        ) +
        coord_cartesian(expand = FALSE, clip = "off") +
        # theme_void() +
        theme_samizdata() +
        theme_void() +
        # hide y axis
        theme(
            axis.text.y = element_blank(),
            axis.line.y = element_blank(),
            legend.position = "none"
        ) +
        NULL

    export_plot(
        temps_chart,
        filename = paste0(path, "clean.png"),
        height = 300,
        final = F,
        open_file = F
    )

    # add labels
    temps_chart_labels <- temps_chart +
        geom_line(
            aes(y = temp_line_rolling),
            color = "white",
            linewidth = 2.5,
            lineend = "round"
        ) +
        geom_line(
            aes(y = temp_line_rolling),
            color = samizcolour("gray_80"),
            linewidth = 1.5,
            lineend = "round"
        ) +
        # min and max labels
        geom_shadowtext(
            data = temps_country |>
                filter(temp == min(temp)),
            aes(
                x = date,
                y = temp_line,
                label = paste0(year(date), "\n", round(temp, 1), "°C")
            ),
            vjust = 1.3,
            size = 4.5,
            family = "Roboto",
            bg.color = samizcolour("gray_80"),
            lineheight = 0.8
        ) +
        geom_shadowtext(
            data = temps_country |>
                filter(temp == max(temp)),
            aes(
                x = date,
                y = temp_line,
                label = paste0(year(date), "\n", round(temp, 1), "°C")
            ),
            vjust = -.3,
            size = 4.5,
            family = "Roboto",
            bg.color = samizcolour("gray_80"),
            lineheight = 0.8
        ) +
        labs(
            title = paste0("A warming ", selected_country),
            subtitle = paste0(
                "Average annual temperature in degrees Celsius, ",
                year(min(temps_country$date)),
                " to ",
                year(max(temps_country$date))
            ),
            caption = "Sources: Berkeley Earth, Copernicus Climate Change Service (via Our World in Data)"
            # alt = "A dot plot showing the estimated number of deaths in the Russian invasion of Ukraine. The majority of deaths are Russian invaders, followed by Ukrainian soldiers and civilians. All are in the low hundreds of thousands."
        ) +
        theme_samizdata() +
        theme(
            axis.text.y = element_blank(),
            axis.line.y = element_blank(),
            legend.position = "none"
        )

    export_plot(
        temps_chart_labels,
        filename = paste0(path, "labels.png"),
        height = 500,
        final = F,
        open_file = F
    )
}


##---------------------------------------------------------------
##            Create charts for all of Eastern Europe           -
##---------------------------------------------------------------

create_chart(temps_year, "Moldova")

map(unique(temps_year$country), create_chart, temps_year = temps_year)


temps_year |>
    filter(country == "Moldova") |>
    mutate(temp_roll = zoo::rollmean(temp, k = 10, fill = NA)) |>
    ggplot(aes(x = date, y = temp_roll)) +
    geom_line()


temps_year |>
    filter(country == "Moldova") |>
    mutate(temp_roll = zoo::rollmean(temp, k = 10, fill = NA)) |>
    View()
