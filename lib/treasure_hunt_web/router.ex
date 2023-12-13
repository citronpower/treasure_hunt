defmodule TreasureHuntWeb.Router do
  use TreasureHuntWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TreasureHuntWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TreasureHuntWeb do
    pipe_through :browser

    # get "/", PageController, :home # DEPRECATED
	  # get "/", PageController, :join # DEPRECATED
    # get "/join", PageController, :join # DEPRECATED
    # post "/register", PageController, :register # DEPRECATED
    live "/", GameArea
  end

  # Other scopes may use custom stacks.
  # scope "/api", TreasureHuntWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:treasure_hunt, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TreasureHuntWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
