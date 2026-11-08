from django.utils.cache import add_never_cache_headers


class ApiNeverCacheMiddleware:
    """/api/ 配下のレスポンスに Cache-Control: no-store 等を付与する。

    API はユーザーごとの可変データを返すため、クライアント(特に iOS の URLSession)が
    ヒューリスティックキャッシュで古い GET レスポンスを再利用しないようにする。
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        if request.path.startswith('/api/'):
            add_never_cache_headers(response)
        return response
