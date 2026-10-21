// SPDX-License-Identifier: GPL-3.0-only

mod components;
mod config;
mod dnd;
mod identity;
mod layout;
mod subscriptions;

pub const APP_ID: &str = "io.github.Aenes0.CosmicTray";

fn main() -> cosmic::iced::Result {
    tracing_subscriber::fmt()
        .with_writer(std::io::stderr)
        // A write that fails is dropped: told on stderr, if that is what
        // failed, it would abort the program.
        .log_internal_errors(false)
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "warn,cosmic_ext_applet_tray=info".into()),
        )
        .init();
    let _ = tracing_log::LogTracer::init();

    tracing::info!("Starting tray applet with version {}", env!("CARGO_PKG_VERSION"));

    components::app::main()
}
