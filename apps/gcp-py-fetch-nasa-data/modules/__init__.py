from . import apod, donki, epic, mars_rover_photos, nasa_image_and_video_library
from . import earth, eonet, exoplanet, insight, open_science_data_repository
from . import satellite_situation_center, ssd_cneos, techport, tle_api, asteroids_neows
from . import vesta_moon_mars_trek_wmts

MODULE_REGISTRY = {
    "apod": apod.fetch,
    "donki": donki.fetch,
    "epic": epic.fetch,
    "mars_rover_photos": mars_rover_photos.fetch,
    "nasa_image_and_video_library": nasa_image_and_video_library.fetch,
    "earth": earth.fetch,
    "eonet": eonet.fetch,
    "exoplanet": exoplanet.fetch,
    "insight": insight.fetch,
    "open_science_data_repository": open_science_data_repository.fetch,
    "satellite_situation_center": satellite_situation_center.fetch,
    "ssd_cneos": ssd_cneos.fetch,
    "techport": techport.fetch,
    "tle_api": tle_api.fetch,
    "asteroids_neows": asteroids_neows.fetch,
    "vesta_moon_mars_trek_wmts": vesta_moon_mars_trek_wmts.fetch,
}
