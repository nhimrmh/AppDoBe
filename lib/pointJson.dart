class pointJson{
  List<double> score;

  pointJson(this.score);

  Map<String,dynamic> toJson(){
    return{
      "score": score
    };
  }
}