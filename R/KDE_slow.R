#' Kernel Density Estimation exposure
#'
#' @description
#' working in all projections but slow
#'
#'
#' @param x data frame with lon lat coordinate columns
#' @param day string in date format compatible with date column in x
#' @param cellsize size of raster cell in meters
#' @param bandwidth bandwidth in meters
#' @param env_data SparRaster object of envirinmental data
#' @param normalize argument if activity data should be normalized to 0-1 values range
#' @param data_extent TODO
#' @param start_crs coordinate system of coordinates in x data frame
#' @param end_crs coordinate system of output
#' @param stats statistics calculated
#' @param act_and_env TODO
#'
#' @return list of SpatRaster result and list of statistics
#'
#'
#'
#'
#' @export
KDE_slow = function(x, day=NULL, cellsize=100, bandwidth = 200, env_data=NULL,
                        normalize = FALSE, data_extent = NULL, # TODO extent
                        start_crs = "WGS84", end_crs=NULL, stats=NULL,
                        act_and_env=FALSE){ # TODO act_and_env


  x_proj = start_processing(x, day, env_data, data_extent, start_crs, end_crs)


  if (!is.null(env_data)){ # change env_data crs beforehand
    env_data_proj = terra::project(env_data, terra::crs(x_proj))
  }

  if (is.numeric(cellsize) & cellsize > 0) { # cellsize included

    grid_rast = terra::rast(crs = terra::crs(x_proj), extent = terra::ext(x_proj),
                             resolution = cellsize)
  } else if (!is.null(env_data)){ #if incorrect cellsize and env_data exists

    grid_rast = env_data_proj
    terra::ext(grid_rast) = terra::ext(x_proj)
  }



  spat_kde_rast = SpatialKDE::kde(sf::st_as_sf(x_proj), band_width = bandwidth,
                                  grid = raster::raster(grid_rast)) #cant use terra rast
  if (normalize == TRUE){

    spat_kde_rast = terra::subst(spat_kde_rast, from = NA, to = 0) # proper range for normalization
    rast_minmax = terra::minmax(spat_kde_rast) # minmax
    # calculate normalization to 0-1 range
    spat_kde_rast = (spat_kde_rast - rast_minmax[1,])/(rast_minmax[2,]-rast_minmax[1,])
    spat_kde_rast = terra::subst(spat_kde_rast, from = 0, to = NA) # insert NA

  }


  spat_kde_rast[spat_kde_rast == 0] = NA


  spat_kde_rast = terra::rast(spat_kde_rast)

  if (!is.null(env_data)){ # calculate exposure
    env_data_resamp = terra::resample(env_data_proj, spat_kde_rast)
    rast_env_kde = spat_kde_rast * env_data_resamp




    # calculate env output
    output = output_calc(act_rast = spat_kde_rast, env_rast = rast_env_kde, stats = stats)
  } else {
    # calculate activity output
    output = output_calc(act_rast = spat_kde_rast, stats = stats)
  }


  return(output)




}
