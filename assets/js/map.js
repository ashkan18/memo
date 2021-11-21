import { interestTypeString } from "./util";

mapboxgl.accessToken =
  "pk.eyJ1IjoiYXNoa2FuMTgiLCJhIjoiY2pzdnk5eGRpMGMxcTN5bzRsOHRjdDR2cCJ9.qaLMKiKsDDLnMPLJ-s4rIQ";

export const map = new mapboxgl.Map({
  container: "map",
  style: "mapbox://styles/mapbox/dark-v10",
  zoom: 11,
});

map.on("render", () => {
  map.resize();
});

map.on("load", () => {
  map.addSource("interestsResults", {
    type: "geojson",
    data: {
      type: "FeatureCollection",
      features: [],
    },
    cluster: true,
    clusterMaxZoom: 14, // Max zoom to cluster points on
    clusterRadius: 50,
  });

  map.addLayer({
    id: "interests-clusters",
    type: "circle",
    source: "interestsResults",
    filter: ["has", "point_count"],
    paint: {
      "circle-stroke-color": "white",
      "circle-color": "#3cb371", // any other store type,
      "circle-radius": ["step", ["get", "point_count"], 10, 5, 20, 10, 5],
    },
  });
  map.addLayer({
    id: "interests-cluster-count",
    type: "symbol",
    source: "interestsResults",
    filter: ["has", "point_count"],
    layout: {
      "text-field": "{point_count_abbreviated}",
      "text-font": ["DIN Offc Pro Medium", "Arial Unicode MS Bold"],
      "text-size": 12,
    },
  });

  map.addLayer({
    id: "interests-point",
    type: "circle",
    source: "interestsResults",
    filter: ["!", ["has", "point_count"]],
    paint: {
      "circle-stroke-color": "white",
      "circle-color": [
        "match",
        ["get", "type"],
        "watched",
        "#FF8C00",
        "read",
        "#008000",
        "listened",
        "#9ACD32",
        "orange", // any other store type
      ],
      "circle-radius": 8,
    },
  });

  // inspect a cluster on click
  map.on("click", "interests-clusters", (e) => {
    const features = map.queryRenderedFeatures(e.point, {
      layers: ["interests-clusters"],
    });
    const clusterId = features[0].properties.cluster_id;
    map
      .getSource("interestsResults")
      .getClusterExpansionZoom(clusterId, (err, zoom) => {
        if (err) return;

        map.easeTo({
          center: features[0].geometry.coordinates,
          zoom: zoom,
        });
      });
  });

  map.on("click", "interests-point", (e) => {
    const coordinates = e.features[0].geometry.coordinates.slice();

    // Ensure that if the map is zoomed out such that multiple
    // copies of the feature are visible, the popup appears
    // over the copy being pointed to.
    while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
      coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
    }
    //map.easeTo({ center: [coordinates[0] - 0.0001, coordinates[1] - 0.0001] });
    new mapboxgl.Popup({
      className: "interest-popup",
      closeButton: false,
      closeOnMove: true,
      maxWidth: "420px",
    })
      .setLngLat(coordinates)
      .setHTML(interestPopup(e.features[0]))
      .addTo(map);
  });

  map.on("mouseenter", "interests-clusters", () => {
    map.getCanvas().style.cursor = "pointer";
  });

  // Change it back to a pointer when it leaves.
  map.on("mouseleave", "interests-clusters", () => {
    map.getCanvas().style.cursor = "";
  });
});

const interestPopup = (interestFeature) => `
  <section class="item item-${interestFeature.properties.type}">
    <div class="item-thumbnail">
      <img src="${interestFeature.properties.thumbnail}"/>
    </div>
    <div class="item-detail">
      <div> 
      <a data-phx-link="patch" data-phx-link-state="push" href="?username=${
        interestFeature.properties.username
      }">${interestFeature.properties.username}</a> ${interestTypeString(
  interestFeature.properties.type
)}</div>
      <div class="item-popup-title">${interestFeature.properties.title}</div>
      <div> ${interestFeature.properties.creators} </div>
    </div>
  </section>
`;
