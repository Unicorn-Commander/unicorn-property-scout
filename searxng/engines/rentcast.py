from searx.engines.xpath import Engine as XPathEngine

class Engine(XPathEngine):
    name = "RentCast"
    base_url = "https://api.rentcast.io/v1/"
    search_url = base_url + "properties?address={query}" # Placeholder

    categories = ["real_estate", "property_data"]

    def request(self, query, params):
        # RentCast typically requires an API key and specific parameters
        # This is a placeholder. Actual implementation will need API key handling
        # and proper query formatting based on RentCast API docs.
        params["url"] = self.search_url.format(query=query)
        # params["headers"] = {"X-Api-Key": "YOUR_RENTCAST_API_KEY"}
        return params

    def parse_response(self, response):
        results = []
        try:
            data = response.json()
            for item in data.get("data", []):
                results.append({
                    "title": item.get("address", {}).get("fullAddress", ""),
                    "url": "#", # No direct URL for property, link to a detail page if available
                    "content": f"Rent Estimate: ${item.get('rentEstimate', {}).get('rentEstimate', 'N/A')}, Beds: {item.get('bedrooms', 'N/A')}, Baths: {item.get('bathrooms', 'N/A')}",
                    "template": "real_estate_rentcast_result.html"
                })
        except Exception as e:
            self.logger.error(f"Error parsing RentCast data: {e}")
        return results
