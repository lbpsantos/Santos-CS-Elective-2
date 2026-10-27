# my_first_flutter_ui

A new Flutter project.

## Supabase setup

The app initializes Supabase before the Flutter widget tree starts. Get the
project URL and the public anon/publishable key from **Supabase Dashboard ->
Project Settings -> API**.

Create a `.env` file in the project root using `.env.example` as a template:

```text
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

The app loads this file before initializing Supabase. The real `.env` is
ignored by Git, so credentials are not committed to the repository.
Use only the public anon/publishable key in this Flutter client. Never put the
service-role or other secret key in the app.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
