class questionsModel{
  String filePath;
  String answer;
  questionsModel(this.filePath, this.answer);

  factory questionsModel.fromJson(Map<String, dynamic> json){
    return questionsModel(json['question_name'],json['answer']);
  }

  String getFilePath(){
    return filePath;
  }

  String getAnswer(){
    return answer;
  }
}