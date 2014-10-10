# 0.1.0
tag 0.1.0
* Throttle requests using a sliding window with period/max_request and request critera.
* Ban (block) requests matching critera.
* Rack::Defense#setup to configure redis store and throttled and banned responses
