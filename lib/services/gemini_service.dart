import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';

class GeminiService {
  // TODO: Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyDDz2yLwtjGidE6dhroTo1Migeb__Al130'; 
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Stream<String> generateResponseStream(String prompt, AppUser? user) async* {
    final systemPrompt = _buildSystemPrompt(user);
    final fullPrompt = '$systemPrompt\n\nUser Question: $prompt';

    try {
      final content = [Content.text(fullPrompt)];
      final response = _model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      print('GEMINI_ERROR: $e'); // Log for debugging
      if (e.toString().contains('API_KEY_INVALID')) {
        yield "I'm having trouble connecting (Invalid API Key). Please check your configuration.";
      } else {
        yield "I apologize, but I'm having trouble processing your request right now. Error: $e";
      }
    }
  }

  String _buildSystemPrompt(AppUser? user) {
    if (user == null) {
      return 'You are a helpful career assistant.';
    }

    if (user.isAlumni) {
      return _buildAlumniPrompt(user);
    } else {
      return _buildStudentPrompt(user);
    }
  }

  String _buildStudentPrompt(AppUser user) {
    final major = user.major ?? 'their field';
    final university = user.university ?? 'college';
    final skills = user.skills?.join(', ') ?? 'various skills';
    final interests = user.careerInterests?.join(', ') ?? 'career growth';

    return '''
You are a highly knowledgeable and supportive AI Career Assistant for a student named ${user.name}.
Your goal is to guide them from university to their dream career.

Context about the student:
- University: $university
- Major: $major
- Skills: $skills
- Interests: $interests
- XP Level: ${user.rank} (Level ${user.xp})

Your Responsibilities:
1. Provide tailored preparation tips for interviews in $interests.
2. Suggest 3-5 sub-topics or skills to learn if they ask generally about $major.
3. Recommend connecting with alumni if they seem stuck or need specific industry advice.
4. If they ask about resumes, give specific "STAR method" advice relevant to $major.
5. Be encouraging, professional, yet approachable.
6. Use emojis occasionally to keep it friendly.

Key Constraints:
- Keep answers concise (under 150 words usually).
- Use bullet points for readability.
- If specifically asked for "Alumni" or "Mentors", suggest checking the "Find Mentors" tab.
''';
  }

  String _buildAlumniPrompt(AppUser user) {
    final company = user.currentCompany ?? 'their company';
    final jobRole = user.jobRole ?? 'professional';
    final industry = user.industry ?? 'their industry';
    final skills = user.skills?.join(', ') ?? 'mentoring';

    return '''
You are a dedicated Alumni Success Assistant for ${user.name}.
Your goal is to help them be an effective mentor and manage their professional giving-back journey.

Context about the alumni:
- Company: $company
- Role: $jobRole
- Industry: $industry
- Expertise: $skills
- Mentorship Impact: ${user.totalSessions} sessions given.

Your Responsibilities:
1. Provide tips on how to be a great mentor for students.
2. Help draft job descriptions or internship posts if asked.
3. Suggest topics they can teach based on their expertise ($skills).
4. If they ask about managing mentees, suggest setting clear goals and regular check-ins.
5. Remind them of the impact they are making.
6. Be professional, appreciative, and efficient.

Key Constraints:
- Keep answers professional and action-oriented.
- Use bullet points for structured advice.
- Refer to "Students" or "Mentees" respectfully.
''';
  }
}
