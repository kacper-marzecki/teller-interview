defmodule TellerWeb.DashboardLive do
  use TellerWeb, :live_view

  def render(assigns) do
    ~H"""
    <table>
      <thead>
        <tr><th>path</th><th>count</th></tr>
      </thead>
      <tbody>
        <%= for {path, count} <- @request_counts do %>
        <tr><td><%= path %></td> <td><%= count %></td></tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Teller.PubSub, "requests")
    {:ok, assign(socket, :request_counts, %{})}
  end

  def handle_info({:path_requested, request_path}, socket) do
    {:noreply,
     update(socket, :request_counts, fn counts ->
       Map.update(counts, request_path, 1, &(&1 + 1))
     end)}
  end
end
