import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://qawvjbxwoxwpxlcufhjp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFhd3ZqYnh3b3h3cHhsY3VmaGpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzYwNjUsImV4cCI6MjA3NzkxMjA2NX0.JfNo4ixJQHrOGOM8dcBHa6kyrZsGgLFnlfpNTehjoRA',
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
  );
}
