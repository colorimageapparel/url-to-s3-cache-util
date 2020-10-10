FROM ruby:2-alpine
WORKDIR /app
ENV SPACES_NAME ""
ENV SPACES_ENDPOINT ""
ENV SPACES_KEY ""
ENV SPACES_SECRET ""
COPY Gemfile ./
RUN bundle
COPY app.rb ./
CMD ruby app.rb
