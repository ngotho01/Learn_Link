import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

class AppConstants {
  static const List<String> courseFields = [
    'Technology',
    'Business',
    'Film & Media',
    'Healthcare',
    'Engineering',
    'Design',
    'Marketing',
    'Finance',
    'Education',
    'Arts',
  ];

  static const List<String> technologySkills = [
    'Python',
    'Flutter',
    'React',
    'Node.js',
    'Java',
    'JavaScript',
    'Swift',
    'Kotlin',
    'C++',
    'Go',
    'AWS',
    'Docker',
    'Kubernetes',
    'MongoDB',
    'PostgreSQL',
    'MySQL',
    'TensorFlow',
    'TypeScript',
    'GraphQL',
    'Rust',
    'DevOps',
    'CI/CD',
    'Cloud Computing',
    'Cybersecurity',
    'Machine Learning',
    'Data Science',
  ];

  static const List<String> businessSkills = [
    'Project Management',
    'Leadership',
    'Strategy',
    'Analytics',
    'Communication',
    'Negotiation',
    'Sales',
    'Operations',
    'Consulting',
    'Planning',
    'Entrepreneurship',
    'Business Development',
    'Financial Analysis',
    'Risk Management',
    'Customer Relationship Management (CRM)',
    'Supply Chain Management',
    'Human Resources',
    'Change Management',
    'Agile Methodologies',
    'Market Research',
  ];

  static const List<String> filmMediaSkills = [
    'Video Editing',
    'Cinematography',
    'Screenwriting',
    'Directing',
    'Sound Design',
    'Animation',
    'Motion Graphics',
    'Film Production',
    'Visual Effects (VFX)',
    'Storyboarding',
    'Lighting Design',
    'Post-Production',
    'Color Grading',
    'Script Analysis',
    'Media Management',
    'Documentary Filmmaking',
    'Broadcasting',
    'Podcast Production',
    'Photography',
    'Augmented Reality (AR) Content Creation',
  ];

  static const List<String> healthcareSkills = [
    'Nursing',
    'Medical Coding',
    'Patient Care',
    'Clinical Research',
    'Public Health',
    'Healthcare Administration',
    'Pharmacology',
    'Medical Imaging',
    'Physical Therapy',
    'Health Informatics',
    'Epidemiology',
    'Surgical Assistance',
    'Nutrition',
    'Mental Health Counseling',
    'Emergency Medical Services (EMS)',
    'Medical Billing',
    'Healthcare Policy',
    'Telemedicine',
    'Biomedical Research',
    'Rehabilitation Therapy',
  ];

  static const List<String> engineeringSkills = [
    'Mechanical Engineering',
    'Electrical Engineering',
    'Civil Engineering',
    'Structural Analysis',
    'CAD (Computer-Aided Design)',
    'Robotics',
    'Embedded Systems',
    'Circuit Design',
    'Thermodynamics',
    'Finite Element Analysis (FEA)',
    'Control Systems',
    'Geotechnical Engineering',
    'Aerospace Engineering',
    'MATLAB',
    'AutoCAD',
    'Hydraulics',
    'Renewable Energy Systems',
    'Manufacturing Processes',
    'Systems Engineering',
    '3D Printing',
  ];

  static const List<String> designSkills = [
    'UI/UX Design',
    'Graphic Design',
    'Product Design',
    'Web Design',
    'Adobe Photoshop',
    'Adobe Illustrator',
    'Figma',
    'Sketch',
    '3D Modeling',
    'Animation Design',
    'Typography',
    'Branding',
    'Interaction Design',
    'Motion Design',
    'User Research',
    'Prototyping',
    'Visual Communication',
    'Illustration',
    'Game Design',
    'Augmented Reality (AR) Design',
  ];

  static const List<String> marketingSkills = [
    'Digital Marketing',
    'SEO (Search Engine Optimization)',
    'Content Marketing',
    'Social Media Marketing',
    'Email Marketing',
    'Brand Management',
    'Market Research',
    'Advertising',
    'PPC (Pay-Per-Click)',
    'Analytics',
    'Public Relations',
    'Copywriting',
    'Influencer Marketing',
    'Event Marketing',
    'Consumer Behavior Analysis',
    'Marketing Automation',
    'Growth Hacking',
    'Video Marketing',
    'Affiliate Marketing',
    'Community Management',
  ];

  static const List<String> financeSkills = [
    'Financial Planning',
    'Accounting',
    'Investment Analysis',
    'Budgeting',
    'Risk Management',
    'Tax Planning',
    'Financial Modeling',
    'Auditing',
    'Corporate Finance',
    'Wealth Management',
    'Bookkeeping',
    'Financial Reporting',
    'Portfolio Management',
    'Banking Operations',
    'Cost Analysis',
    'Mergers & Acquisitions',
    'Credit Analysis',
    'Blockchain Finance',
    'Fintech',
    'Economic Forecasting',
  ];

  static const List<String> educationSkills = [
    'Curriculum Development',
    'Instructional Design',
    'Classroom Management',
    'Educational Technology',
    'Lesson Planning',
    'Assessment Design',
    'Pedagogy',
    'E-Learning',
    'Special Education',
    'Literacy Coaching',
    'Educational Leadership',
    'Teacher Training',
    'Learning Management Systems (LMS)',
    'Blended Learning',
    'Student Counseling',
    'Education Policy',
    'STEM Education',
    'Language Instruction',
    'Educational Research',
    'Adult Education',
  ];

  static const List<String> artsSkills = [
    'Painting',
    'Sculpture',
    'Photography',
    'Digital Art',
    'Illustration',
    'Art History',
    'Creative Writing',
    'Performing Arts',
    'Music Composition',
    'Theater Production',
    'Choreography',
    'Graphic Arts',
    'Ceramics',
    'Textile Design',
    'Art Curation',
    'Calligraphy',
    'Mixed Media',
    'Art Therapy',
    'Film Criticism',
    'Cultural Studies',
  ];

  static const List<List<Color>> _kSkillPalette = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF0891B2), Color(0xFF06B6D4)],
    [Color(0xFF7C3AED), Color(0xFFA855F7)],
    [Color(0xFF0F766E), Color(0xFF14B8A6)],
    [Color(0xFFB45309), Color(0xFFF59E0B)],
    [Color(0xFFBE123C), Color(0xFFF43F5E)],
    [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    [Color(0xFF065F46), Color(0xFF10B981)],
  ];

}