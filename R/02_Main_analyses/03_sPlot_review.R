#----------------------------------------------------------#
#
#
#                   Vegetation data
#
#                   View the sPlot data
#
#
#                      O. Mottl
#                         2023
#
#----------------------------------------------------------#
# Review the sPlotOpen data to make an overview


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

data_splot <-
  RUtilpol::get_latest_file(
    file_name = "data_splot",
    dir = here::here(
      "Data/Processed/sPlot"
    )
  )


#----------------------------------------------------------#
# 3. EDA  -----
#----------------------------------------------------------#

# All splot datasets
data_splot %>%
  tidyr::drop_na(Longitude, Latitude, Releve_area) %>%
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = Longitude,
      y = Latitude,
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
      title = "sPlotOpen plots with coordinates and plot size",
      x = "Longitude",
      y = "Latitude",
      caption = paste(
        "N datasets = ",
        data_splot %>%
          tidyr::drop_na(Longitude, Latitude, Releve_area) %>%
          nrow()
      )
    )

# select Europe and Oceania as potential splot datasets

# Get the most common plot size
splot_most_common_size <-
  data_splot %>%
  dplyr::distinct(Continent, PlotObservationID, Releve_area) %>%
  tidyr::drop_na() %>%
  dplyr::group_by(Continent, Releve_area) %>%
  dplyr::count() %>%
  dplyr::arrange(desc(n)) %>%
  dplyr::group_by(Continent) %>%
  dplyr::slice(1) %>%
  dplyr::filter(
    Continent %in% c("Europe", "Oceania")
  ) %>%
  purrr::chuck("Releve_area") %>%
  rlang::set_names(
    c("Europe", "Oceania")
  )

data_splot_same_size <-
  data_splot %>%
  dplyr::filter(
    Continent %in% c("Europe", "Oceania")
  ) %>%
  dplyr::mutate(
    is_best = dplyr::case_when(
      Releve_area == splot_most_common_size["Europe"] &
        Continent == "Europe" ~ TRUE,
      Releve_area == splot_most_common_size["Oceania"] &
        Continent == "Oceania" ~ TRUE,
      .default = FALSE
    )
  ) %>%
  dplyr::filter(is_best)

data_splot_same_size_n <-
  data_splot_same_size %>%
  dplyr::distinct(Continent, PlotObservationID, GIVD_ID) %>%
  tidyr::drop_na() %>%
  dplyr::group_by(Continent, GIVD_ID) %>%
  dplyr::count() %>%
  dplyr::arrange(desc(n))

same_size_datasets <-
  data_splot_same_size_n %>%
  purrr::chuck("GIVD_ID")

data_splot_same_size_to_plot <-
  data_splot_same_size %>%
  dplyr::filter(GIVD_ID %in% same_size_datasets)

plot_continental_data <- function(data_source, sel_continent) {
  data_work <-
    data_source %>%
    dplyr::filter(Continent == sel_continent)

  data_work %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = Longitude,
        y = Latitude,
      )
    ) +
    ggplot2::borders(
      fill = "gray80",
      colour = NA
    ) +
    ggplot2::geom_point(
      alpha = 0.5
    ) +
    ggplot2::geom_density2d(
      alpha = 0.5
    ) +
    ggplot2::coord_quickmap(
      xlim = range(data_work$Longitude),
      ylim = range(data_work$Latitude)
    ) +
      ggplot2::theme(
    text = ggplot2::element_text(
      size = 25
    )
  ) +
    ggplot2::labs(
      title = sel_continent,
      x = "Longitude",
      y = "Latitude",
      caption = paste(
        "plot size:", splot_most_common_size[sel_continent], "m2", "\n",
        "N datasets = ", nrow(data_work)
      )
    )
}

ggpubr::ggarrange(
  plot_continental_data(data_splot_same_size_to_plot, "Europe"),
  plot_continental_data(data_splot_same_size_to_plot, "Oceania"),
  widths = c(1, 0.75)
)  %>% 
ggpubr::annotate_figure(
  top = ggpubr::text_grob(
    "sPlot plots with most common plot size",
    face = "bold",
    size = 25,
    hjust = 1
  )
)
