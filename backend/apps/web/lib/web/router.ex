defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Web do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  scope "/", Web do
    pipe_through(:api)

    post("/register", AccountController, :create)
    post("/upload", AccountController, :upload)
    post("/pre_key_bundle", AccountController, :pre_key_bundle)

    if Mix.env() == :dev do
      post("/clean_storage", StorageController, :clean)
    end
  end
end
