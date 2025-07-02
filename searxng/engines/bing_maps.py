from searx.engines.xpath import Engine as XPathEngine

class Engine(XPathEngine):
    name = "Bing Maps"
    base_url = "http://dev.virtualearth.net/REST/v1/"
    search_url = base_url + "Locations?q={query}&key={api_key}" # Placeholder

    categories = ["real_estate", "geographic"]

    def request(self, query, params):
        # Bing Maps requires an API key
        api_key = "YOUR_BING_MAPS_API_KEY"

        params["url"] = self.search_url.format(query=query, api_key=api_key)
        return params

    def parse_response(self, response):
        results = []
        try:
            data = response.json()
            for resource in data.get("resourceSets", [{}])[0].get("resources", []):
                results.append({
                    "title": resource.get("name", ""),
                    "url": "#", # No direct URL for location, might link to map view
                    "content": f"Address: {resource.get('address', {}).get('formattedAddress', '')}, Lat: {resource.get('point', {}).get('coordinates', ['', ''])[0]}, Lon: {resource.get('point', {}).get('coordinates', ['', ''])[1]}",
                    "template": "real_estate_bing_maps_result.html"
                })
        except Exception as e:
            self.logger.error(f"Error parsing Bing Maps data: {e}")
        return results
