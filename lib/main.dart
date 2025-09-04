import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

void main() {
  runApp(MazeGameApp());
}

class MazeGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maze Quest',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Auth Service
class AuthService {
  static const _storage = FlutterSecureStorage();
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:5000/api',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 3),
  ));

  static Future<bool> signup({
    required String name,
    required String rollNumber,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/signup', data: {
        'name': name,
        'rollNumber': rollNumber,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.write(key: 'token', value: response.data['token']);
        await _storage.write(key: 'user', value: response.data['user']['name']);
        return true;
      }
    } catch (e) {
      print('Signup error: $e');
    }
    return false;
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        await _storage.write(key: 'token', value: response.data['token']);
        await _storage.write(key: 'user', value: response.data['user']['name']);
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  static Future<bool> submitScore(int score) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await _dio.post(
        '/scores/submit-score',
        data: {'score': score},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Submit score error: $e');
      return false;
    }
  }

  static Future<String?> getToken() => _storage.read(key: 'token');
  static Future<String?> getUser() => _storage.read(key: 'user');
  static Future<void> logout() => _storage.deleteAll();
}

// Auth Screen
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final token = await AuthService.getToken();
    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MazeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _rollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 60),
                    _buildHeader(),
                    SizedBox(height: 50),
                    _buildAuthCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Icon(
            Icons.games,
            size: 60,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'MAZE QUEST',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        Text(
          'Adventure Awaits',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildToggleButtons(),
              SizedBox(height: 30),
              _buildFormFields(),
              SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLogin = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: isLogin ? Color(0xFF667eea) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLogin ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLogin = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: !isLogin ? Color(0xFF667eea) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !isLogin ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        if (!isLogin) ...[
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _rollController,
            label: 'Roll Number',
            icon: Icons.badge,
            validator: (value) => value!.isEmpty ? 'Please enter roll number' : null,
          ),
          SizedBox(height: 20),
        ],
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          validator: (value) {
            if (value!.isEmpty) return 'Please enter email';
            if (!value.contains('@')) return 'Please enter valid email';
            return null;
          },
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          isPassword: true,
          validator: (value) {
            if (value!.isEmpty) return 'Please enter password';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        labelStyle: TextStyle(color: Colors.grey[600]),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleAuth,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isLogin ? 'LOGIN' : 'SIGN UP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF667eea),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    bool success;
    if (isLogin) {
      success = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      success = await AuthService.signup(
        name: _nameController.text,
        rollNumber: _rollController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MazeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// Maze Screen
class MazeScreen extends StatefulWidget {
  @override
  _MazeScreenState createState() => _MazeScreenState();
}

class _MazeScreenState extends State<MazeScreen>
    with TickerProviderStateMixin {
  int currentLevel = 1;
  int totalScore = 0;
  String? userName;
  late AnimationController _levelAnimationController;
  late Animation<double> _levelAnimation;

  @override
  void initState() {
    super.initState();
    _levelAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _levelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelAnimationController, curve: Curves.elasticOut),
    );
    _levelAnimationController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    userName = await AuthService.getUser();
    setState(() {});
  }

  @override
  void dispose() {
    _levelAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMazeGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome ${userName ?? "Player"}!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Level $currentLevel',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Score',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              ScaleTransition(
                scale: _levelAnimation,
                child: Text(
                  '$totalScore',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMazeGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: 10,
      itemBuilder: (context, index) => _buildGate(index + 1),
    );
  }

  Widget _buildGate(int gateNumber) {
    bool isCompleted = gateNumber < currentLevel;
    bool isCurrent = gateNumber == currentLevel;
    bool isLocked = gateNumber > currentLevel;

    return GestureDetector(
      onTap: isCurrent ? () => _openGate(gateNumber) : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCompleted
                ? [Colors.green, Colors.lightGreen]
                : isCurrent
                    ? [Colors.amber, Colors.orange]
                    : [Colors.grey[600]!, Colors.grey[800]!],
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : isCurrent
                      ? Colors.amber.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle
                  : isCurrent
                      ? Icons.play_circle_filled
                      : Icons.lock,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              'Gate $gateNumber',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isCompleted)
              Text(
                'Completed ✓',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              )
            else if (isCurrent)
              Text(
                'Tap to Play',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              )
            else
              Text(
                'Locked',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openGate(int gateNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          level: gateNumber,
          onComplete: (score) {
            setState(() {
              totalScore += score;
              currentLevel++;
              _levelAnimationController.reset();
              _levelAnimationController.forward();
            });
            
            if (currentLevel > 10) {
              _submitFinalScore();
            }
          },
        ),
      ),
    );
  }

  Future<void> _submitFinalScore() async {
    final success = await AuthService.submitScore(totalScore);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎉 Congratulations!',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You completed all 10 levels!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Final Score: $totalScore',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10),
            Text(
              success ? 'Score submitted successfully!' : 'Score submission failed',
              style: TextStyle(
                color: success ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                currentLevel = 1;
                totalScore = 0;
              });
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }
}

// Quiz Screen
class QuizScreen extends StatefulWidget {
  final int level;
  final Function(int) onComplete;

  QuizScreen({required this.level, required this.onComplete});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int currentQuestion = 0;
  int score = 0;
  bool isAnswered = false;
  
  List<Map<String, dynamic>> questions = [
    {
      'question': 'What is 2 + 2?',
      'options': ['3', '4', '5', '6'],
      'correct': 1,
    },
    {
      'question': 'Which planet is known as the Red Planet?',
      'options': ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      'correct': 1,
    },
    {
      'question': 'What is the capital of France?',
      'options': ['London', 'Berlin', 'Paris', 'Madrid'],
      'correct': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF21CBF3),
              Color(0xFF2196F3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 30),
                _buildProgressBar(),
                SizedBox(height: 30),
                Expanded(child: _buildQuestionCard()),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          'Level ${widget.level}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Score: $score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (currentQuestion + 1) / questions.length * _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard() {
    final question = questions[currentQuestion];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Question ${currentQuestion + 1} of ${questions.length}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              question['question'],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ...List.generate(
              question['options'].length,
              (index) => _buildOptionButton(
                question['options'][index],
                index,
                question['correct'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, int index, int correctIndex) {
    Color buttonColor = Colors.grey[200]!;
    Color textColor = Colors.grey[800]!;
    
    if (isAnswered) {
      if (index == correctIndex) {
        buttonColor = Colors.green;
        textColor = Colors.white;
      }
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: isAnswered ? null : () => _selectAnswer(index, correctIndex),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isAnswered ? _nextQuestion : null,
        child: Text(
          currentQuestion == questions.length - 1 ? 'Complete Level' : 'Next Question',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2196F3),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  void _selectAnswer(int selectedIndex, int correctIndex) {
    setState(() {
      isAnswered = true;
      if (selectedIndex == correctIndex) {
        score += 100;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        isAnswered = false;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      widget.onComplete(score);
      Navigator.pop(context);
    }
  }
}