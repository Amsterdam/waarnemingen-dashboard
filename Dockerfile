FROM grafana/grafana:7.5.4

USER root

# Docs: https://grafana.com/docs/grafana/latest/installation/docker/#build-with-grafana-image-renderer-plugin-pre-installed
ARG GF_INSTALL_IMAGE_RENDERER_PLUGIN="true"

ENV GF_PATHS_PLUGINS="/var/lib/grafana-plugins"

RUN mkdir -p "$GF_PATHS_PLUGINS" && \
    chown -R grafana "$GF_PATHS_PLUGINS"

RUN if [ $GF_INSTALL_IMAGE_RENDERER_PLUGIN = "true" ]; then \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --no-cache  upgrade && \
    apk add --no-cache udev ttf-opensans chromium && \
    rm -rf /tmp/* && \
    rm -rf /usr/share/grafana/tools/phantomjs; \
fi

USER grafana

# This env var has changed to the underlying, event though it is not documented: https://github.com/grafana/grafana-image-renderer/blob/2e721c160b0005ba4a16220c31c96d0a6349d5d8/src/plugin/v2/grpc_plugin.ts#L186
ENV GF_PLUGIN_RENDERING_CHROME_BIN="/usr/bin/chromium-browser"

RUN if [ $GF_INSTALL_IMAGE_RENDERER_PLUGIN = "true" ]; then \
    grafana-cli \
        --pluginsDir "$GF_PATHS_PLUGINS" \
        --pluginUrl https://github.com/grafana/grafana-image-renderer/releases/latest/download/plugin-linux-x64-glibc-no-chromium.zip \
        plugins install grafana-image-renderer; \
fi

ARG GF_INSTALL_PLUGINS=""

RUN echo ${GF_INSTALL_PLUGINS}

RUN if [ -n "${GF_INSTALL_PLUGINS}" ]; then \
    OLDIFS=$IFS; \
        IFS=','; \
    for plugin in ${GF_INSTALL_PLUGINS}; do \
        IFS=$OLDIFS; \
        grafana-cli --pluginsDir "$GF_PATHS_PLUGINS" plugins install ${plugin}; \
    done; \
fi

ADD provisioning/dashboards /etc/grafana/provisioning/dashboards
ADD provisioning/datasources /etc/grafana/provisioning/datasources
ADD dashboards /var/lib/grafana/dashboards

ADD deploy /deploy
