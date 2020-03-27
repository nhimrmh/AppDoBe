class questionsModel{
  String filePath;
  bool answer;
  questionsModel(this.filePath, this.answer);

  factory questionsModel.fromJson(Map<String, dynamic> json){
    return questionsModel(json['question_name'],json['answer']);
  }
}