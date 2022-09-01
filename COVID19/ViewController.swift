//
//  ViewController.swift
//  COVID19
//
//  Created by Yongwoo Yoo on 2022/03/18.
//

import UIKit
import Alamofire
import Charts

class ViewController: UIViewController {

	@IBOutlet weak var totalCaseLabel: UILabel!
	@IBOutlet weak var newCaseLabel: UILabel!
	
	@IBOutlet weak var pieChartView: PieChartView!
	
	@IBOutlet weak var labelStackView: UIStackView!
	@IBOutlet weak var indicatorView: UIActivityIndicatorView!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.indicatorView.startAnimating() //indicator 시작
		self.fetchCovidOverview(completionHandler: { [weak self] result in
			guard let self = self else { return }
			self.indicatorView.stopAnimating()
			self.indicatorView.isHidden = true
			self.labelStackView.isHidden = false
			self.pieChartView.isHidden = false
			
			switch result {
				case let .success(result):
					debugPrint("success \(result)")
					self.configureStackView(koreaCovidOverview: result.korea)
				let covidOverviewList = self.makeCovidOverviewList(citycovidOverview: result)
					self.configureChartView(covidOverviewList: covidOverviewList)
				case let .failure(error):
					debugPrint("error \(error)")
			}
		
		})
	}
	
	func makeCovidOverviewList(
		citycovidOverview: CityCovidOverview
	) -> [CovidOverview] {
		return [
			citycovidOverview.seoul,
			citycovidOverview.busan,
			citycovidOverview.daegu,
			citycovidOverview.incheon,
			citycovidOverview.gwangju,
			citycovidOverview.daejeon,
			citycovidOverview.ulsan,
			citycovidOverview.sejong,
			citycovidOverview.gyeonggi,
			citycovidOverview.gangwon,
			citycovidOverview.chungbuk,
			citycovidOverview.chungnam,
			citycovidOverview.jeonbuk,
			citycovidOverview.jeonnam,
			citycovidOverview.gyeongbuk,
			citycovidOverview.gyeongnam,
			citycovidOverview.jeju,
		]
	}
	
	func configureChartView(covidOverviewList: [CovidOverview]){
		self.pieChartView.delegate = self
		
		let entries = covidOverviewList.compactMap { [weak self] overview -> PieChartDataEntry? in
			guard let self = self else { return nil }
			return PieChartDataEntry(
				value: removeFormatString(string: overview.newCase),
				label: overview.countryName,
				data: overview)
		}
		
		let dataSet = PieChartDataSet(entries: entries, label: "코로나 발생 현황")
		dataSet.sliceSpace =  1
		dataSet.entryLabelColor = .black
		dataSet.valueTextColor = .black
		dataSet.xValuePosition = .outsideSlice
		dataSet.valueLinePart1OffsetPercentage = 0.8
		dataSet.valueLinePart1Length = 0.2
		dataSet.valueLinePart2Length = 0.3
		
		dataSet.colors = ChartColorTemplates.vordiplom() + ChartColorTemplates.joyful() + ChartColorTemplates.liberty() + ChartColorTemplates.pastel() + ChartColorTemplates.material()
		
		self.pieChartView.data = PieChartData(dataSet: dataSet)
		self.pieChartView.spin(duration: 0.3, fromAngle: self.pieChartView.rotationAngle, toAngle: self.pieChartView.rotationAngle + 80) //80도 회전
	}
	
	func removeFormatString(string: String) -> Double {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		return formatter.number(from: string)?.doubleValue ?? 0 // nil이면 0
		
	}
	
	func configureStackView(koreaCovidOverview: CovidOverview){
		self.totalCaseLabel.text = "\(koreaCovidOverview.totalCase)명"
		self.newCaseLabel.text = "\(koreaCovidOverview.newCase)"
	}

	//비동기, 네트워크의 경우 서버에서 response가 언제올지 모르기 때문
	func fetchCovidOverview(
		completionHandler: @escaping (Result<CityCovidOverview, Error>) -> Void
	){
		let url = "https://api.corona-19.kr/korea/country/new/"
		let param = [
			"serviceKey" : "z3FdOmBQsgaqGhyDJS12ev47Xcf5tbYLo"
		]
		AF.request(url, method: .get, parameters: param).responseData(completionHandler:{ response in
		switch response.result {
		   case let .success(data):
			   do {
				   let decoder = JSONDecoder()
				   let result =  try decoder.decode(CityCovidOverview.self, from: data)
				   completionHandler(.success(result))
			   } catch {
				   completionHandler(.failure(error))
			   }
			   
		   case let .failure(error):
			   completionHandler(.failure(error))
		   }
		   
	   })
		
		//체이닝
		
	}
}

extension ViewController: ChartViewDelegate {
	func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
		guard let covidDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "CovidDetailViewController") as? CovidDetailViewController else { return }
		guard let covidOverview = entry.data as? CovidOverview else { return }
		covidDetailViewController.covidOverview = covidOverview
		self.navigationController?.pushViewController(covidDetailViewController, animated: true)
		
	}
	
	
}
