from searx.engines.xpath import Engine as XPathEngine

class Engine(XPathEngine):
    name = "SchoolDigger"
    base_url = "https://api.schooldigger.com/v2/"
    search_url = base_url + "schools?q={query}&appID={appID}&appKey={appKey}" # Placeholder

    categories = ["real_estate", "schools"]

    def request(self, query, params):
        # SchoolDigger requires appID and appKey
        # These should be loaded from environment variables or settings.yml
        app_id = "YOUR_SCHOOLDIGGER_APP_ID"
        app_key = "YOUR_SCHOOLDIGGER_APP_KEY"

        params["url"] = self.search_url.format(query=query, appID=app_id, appKey=app_key)
        return params

    def parse_response(self, response):
        results = []
        try:
            data = response.json()
            for school in data.get("schoolList", []):
                results.append({
                    "title": school.get("schoolName", ""),
                    "url": school.get("url", ""),
                    "content": f"District: {school.get('districtName', '')}, Grade Level: {school.get('lowGrade', '')}-{school.get('highGrade', '')}, Rating: {school.get('overallRank', 'N/A')}",
                    "template": "real_estate_schooldigger_result.html"
                })
        except Exception as e:
            self.logger.error(f"Error parsing SchoolDigger data: {e}")
        return results
