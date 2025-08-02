#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                     EDA of BIEN data
#
#
#                      O. Mottl
#                         2023
#
#----------------------------------------------------------#
# EDA bien data


#----------------------------------------------------------#
# 1. Set up -----
#----------------------------------------------------------#

# Load configuration
source(
  here::here(
    "R/00_Config_file.R"
  )
)

#----------------------------------------------------------#
# 2. Load data  -----
#----------------------------------------------------------#

data_bien <-
  RUtilpol::get_latest_file(
    file_name = "data_bien",
    dir = here::here(
      "Data/Processed/BIEN"
    )
  )


#----------------------------------------------------------#
# 3. EDA  -----
#----------------------------------------------------------#

names(data_bien)

# All splot datasets
data_bien %>%
  tidyr::drop_na(longitude, latitude, plot_area_ha) %>%
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = longitude,
      y = latitude,
    )
  ) +
  ggplot2::borders(
    fill = "gray80",
    colour = NA
  ) +
  ggplot2::geom_point(alpha = 0.1) +
  ggplot2::geom_density2d() +
  ggplot2::coord_quickmap() +
  ggplot2::theme(
    text = ggplot2::element_text(
      size = 25
    )
  ) +
  ggplot2::labs(
    title = "BIEN plots with coordinates and plot size",
    x = "Longitude",
    y = "Latitude",
    caption = paste(
      "N datasets = ",
      data_bien %>%
        tidyr::drop_na(longitude, latitude, plot_area_ha) %>%
        nrow()
    )
  )

# Get the most common size
bien_most_common_size <-
  data_bien %>%
  tidyr::drop_na(longitude, latitude, plot_area_ha) %>%
  dplyr::distinct(
    datasource, methodology_reference,
    datasource_id, plot_name, plot_area_ha,
    .keep_all = TRUE
  ) %>%
  dplyr::mutate(
    continent = dplyr::case_when(
      .default = "Other",
      latitude > 18 & longitude < -40 ~ "North America",
      latitude < 18 & longitude < -40 ~ "Latin America"
    )
  ) %>%
  dplyr::group_by(continent, plot_area_ha) %>%
  dplyr::count() %>%
  dplyr::arrange(desc(n)) %>%
  dplyr::group_by(continent) %>%
  dplyr::slice(1) %>%
  dplyr::filter(
    continent %in% c("North America", "Latin America")
  ) %>%
  purrr::chuck("plot_area_ha") %>%
  rlang::set_names(
    c("North America", "Latin America")
  )

data_bien_same_size <-
  data_bien %>%
  tidyr::drop_na(longitude, latitude, plot_area_ha) %>%
  dplyr::mutate(
    continent = dplyr::case_when(
      .default = "Other",
      latitude > 18 & longitude < -40 ~ "North America",
      latitude < 18 & longitude < -40 ~ "Latin America"
    )
  ) %>%
  dplyr::filter(
    continent %in% c("North America", "Latin America")
  ) %>%
  dplyr::mutate(
    is_best = dplyr::case_when(
      plot_area_ha == bien_most_common_size["North America"] &
        continent == "North America" ~ TRUE,
      plot_area_ha == bien_most_common_size["Latin America"] &
        continent == "Latin America" ~ TRUE,
      .default = FALSE
    )
  ) %>%
  dplyr::filter(is_best)

data_bien_same_size %>%
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = longitude,
      y = latitude,
    )
  ) +
  ggplot2::borders(
    fill = "gray80",
    colour = "gray80"
  ) +
  ggplot2::geom_point(
    alpha = 0.5
  ) +
  ggplot2::geom_density2d(
    alpha = 0.5
  ) +
  ggplot2::coord_quickmap(
    xlim = range(data_bien_same_size$longitude),
    ylim = range(data_bien_same_size$latitude)
  ) +
  ggplot2::theme(
    text = ggplot2::element_text(
      size = 25
    )
  ) +
  ggplot2::labs(
    title = "BIEN plots with most common plot size",
    x = "Longitude",
    y = "Latitude",
    caption = paste(
      "plot size:", bien_most_common_size * 1e4, "m2", "\n",
      "N datasets = ", nrow(data_bien_same_size)
    )
  )
