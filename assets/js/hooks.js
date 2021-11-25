import { map } from "./map";

export const Hooks = {};

Hooks.BeforeUnload = {
  mounted() {
    var el = this.el;
    this.beforeUnload = function (e) {
      if (el.dataset.changesMade === "true") {
        e.preventDefault();
        e.returnValue = "";
      }
    };
    window.addEventListener("beforeunload", this.beforeUnload, true);
  },
  destroyed() {
    window.removeEventListener("beforeunload", this.beforeUnload, true);
  },
};

Hooks.MapThingsHandler = {
  mounted() {
    navigator.geolocation.getCurrentPosition((position) => {
      const { latitude, longitude } = position.coords;
      this.pushEvent("setLocation", { longitude, latitude });
      map.setCenter([longitude, latitude]);
      const el = document.createElement("span");
      el.className =
        "animate-pulse h-8 w-8 rounded-full bg-red-400 opacity-75 box-border border-2 shadow-2xl";
      new mapboxgl.Marker(el).setLngLat([longitude, latitude]).addTo(map);
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
            creators: i.creators,
            user_id: i.user.id,
            username: i.user.username,
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
