//
//  resultsViewController.swift
//  Garbify
//
//  Created by Nirbhay Singh on 12/07/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit

class resultsViewController: UIViewController {

    @IBOutlet weak var predLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var plastic1Lbl: UILabel!
    @IBOutlet weak var plastic2Lbl: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if(!plastic){
            plastic1Lbl.isHidden = true
            plastic2Lbl.isHidden = true
        }
        if(!predi.hasSuffix(" trash")) {predi+=" trash"}
        plastic2Lbl.text = plasticPred
        confidenceLbl.text = confidence_str + "%"
        predLbl.text = predi
        // Do any additional setup after loading the view.
    }
    @IBAction func infoBtnPressed(_ sender: Any) {
        if(predi=="cardboard trash"){
            showInfo(msg: """
            Yes! Cardboard can be recycled in fact it can be recycled up to 5 times.

            A country can create upto 400 billion square feet of cardboard in a year!

            By recycling cardboard, you would be saving 50% of the pollution that would have been released if you trashed it!
        """, title: "Recycle it!")
        }else if(predi=="plastic trash")
        {
            showInfo(msg: """
            More than 8 million tonnes of plastic is dumped into the ocean every year!

            Only 8% of totally recyclable plastic actually ends up getting recycled

            Over 90% of bird species are chewing on your plastic right now!

            """, title: "Recycle it!")
        }else if(predi=="organic trash"){
            showInfo(msg: """
            Try finding a compost site nearby!

            You can save over 25% of your waste if you decide to compost your organic waste

            You can save 10 people from respiratory diseases. This waste is likely to be burnt and worsen the AQI in your city

            """, title: "Use it as compost!")
        }else if(predi=="paper trash"){
            showInfo(msg: """
            Paper produced from recycled paper represents an energy saving of 70%

            As you read this information, over 200 tonnes of paper was just produced

            The newspaper you receive everyday is made up of 75,000 trees


            """, title: "Recycle it!")
        }
        else if(predi=="metal trash"){
            showInfo(msg: """
            If you have any sort of electronic waste, please employ e-waste recycling options.

            Making new products from recycled steel cans helps save up to 75% of the energy and 40% of the water needed to make steel from raw materials



            """, title: "Maybe recycable")
        }
        else {
            showInfo(msg: """
            You can recycle glass!
            Try finding a recycling plant nearby!
            """, title: "Recycle it!")
        }
    }
}
