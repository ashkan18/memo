import { map } from "./map";

export const Hooks = {};

Hooks.MapThingsHandler = {
  mounted() {
    navigator.geolocation.getCurrentPosition((position) => {
      const { latitude, longitude } = position.coords;
      map.setCenter([longitude, latitude]);
      this.pushEvent("search", { longitude, latitude });
    });

    const handleSearchResults = ({ interests }) => {
      const featuresGeoJson = interests.map((i) => {
        return {
          type: "Feature",
          id: i.id,
          geometry: {
            type: "Point",
            coordinates: [i.location.latitude, i.location.longitude],
          },
          properties: {
            title: i.title,
            description: i.title,
            type: i.type,
            thumbnail: i.thumbnail,
          },
        };
      });
      map.getSource("interestsResults").setData({
        type: "FeatureCollection",
        features: featuresGeoJson,
      });
    };

    // handle new sightings as they show up
    this.handleEvent("search_results", handleSearchResults);
  },
};
