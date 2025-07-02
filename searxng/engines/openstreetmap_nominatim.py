from searx.engines.xpath import Engine as XPathEngine

class Engine(XPathEngine):
    name = "OpenStreetMap Nominatim"
    base_url = "https://nominatim.openstreetmap.org/"
    search_url = base_url + "search?format=json&q={query}"

    categories = ["real_estate", "geographic"]

    def request(self, query, params):
        params["url"] = self.search_url.format(query=query)
        return params

    def parse_response(self, response):
        results = []
        try:
            data = response.json()
            for item in data:
                results.append({
                    "title": item.get("display_name", ""),
                    "url": item.get("osm_url", ""),
                    "content": f"Type: {item.get('type', '')}, Class: {item.get('class', '')}, Lat: {item.get('lat', '')}, Lon: {item.get('lon', '')}",
                    "template": "real_estate_osm_result.html" # Custom template for this result
                })
        except Exception as e:
            self.logger.error(f"Error parsing OpenStreetMap Nominatim data: {e}")
        return results
