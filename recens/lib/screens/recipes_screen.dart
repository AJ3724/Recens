import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/app_header.dart';
import '../config/api_config.dart';

// ── Embedded recipe data ───────────────────────────────────────────────────────
const String _kRecipesJson = r'''
[{"id":1,"name":"Tabbouleh","category":"Side Dish","ingredients":[{"name":"Parsley","qty":2,"unit":"cups"},{"name":"Tomato","qty":2,"unit":"units"},{"name":"Bulgur","qty":0.5,"unit":"cup"}]},{"id":2,"name":"Fattoush","category":"Side Dish","ingredients":[{"name":"Lettuce","qty":1,"unit":"head"},{"name":"Tomato","qty":2,"unit":"units"},{"name":"Pita Bread","qty":1,"unit":"piece"}]},{"id":3,"name":"Hummus","category":"Appetizer","ingredients":[{"name":"Chickpeas","qty":1,"unit":"cup"},{"name":"Tahini","qty":2,"unit":"tbsp"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"}]},{"id":4,"name":"Baba Ghanoush","category":"Appetizer","ingredients":[{"name":"Eggplant","qty":1,"unit":"unit"},{"name":"Tahini","qty":2,"unit":"tbsp"},{"name":"Garlic","qty":2,"unit":"cloves"}]},{"id":5,"name":"Kibbeh","category":"Main Dish","ingredients":[{"name":"Minced Meat","qty":300,"unit":"grams"},{"name":"Bulgur","qty":1,"unit":"cup"},{"name":"Onion","qty":1,"unit":"unit"}]},{"id":6,"name":"Falafel","category":"Snack","ingredients":[{"name":"Chickpeas","qty":1,"unit":"cup"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Parsley","qty":1,"unit":"cup"}]},{"id":7,"name":"Shawarma Chicken","category":"Main Dish","ingredients":[{"name":"Chicken","qty":300,"unit":"grams"},{"name":"Garlic Sauce","qty":3,"unit":"tbsp"},{"name":"Pita Bread","qty":2,"unit":"pieces"}]},{"id":8,"name":"Shawarma Meat","category":"Main Dish","ingredients":[{"name":"Beef","qty":300,"unit":"grams"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Pita Bread","qty":2,"unit":"pieces"}]},{"id":9,"name":"Manakish Zaatar","category":"Breakfast","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Zaatar","qty":3,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":10,"name":"Manakish Cheese","category":"Breakfast","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Cheese","qty":1,"unit":"cup"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":11,"name":"Mjadara","category":"Main Dish","ingredients":[{"name":"Lentils","qty":1,"unit":"cup"},{"name":"Rice","qty":0.5,"unit":"cup"},{"name":"Onion","qty":2,"unit":"units"},{"name":"Olive Oil","qty":3,"unit":"tbsp"},{"name":"Cumin","qty":1,"unit":"tsp"}]},{"id":12,"name":"Warak Enab","category":"Main Dish","ingredients":[{"name":"Grape Leaves","qty":30,"unit":"pieces"},{"name":"Rice","qty":1,"unit":"cup"},{"name":"Minced Meat","qty":200,"unit":"grams"},{"name":"Tomato","qty":2,"unit":"units"},{"name":"Lemon Juice","qty":3,"unit":"tbsp"}]},{"id":13,"name":"Kafta","category":"Main Dish","ingredients":[{"name":"Minced Meat","qty":400,"unit":"grams"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Parsley","qty":0.5,"unit":"cup"},{"name":"Cumin","qty":1,"unit":"tsp"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"}]},{"id":14,"name":"Loubieh","category":"Side Dish","ingredients":[{"name":"Green Beans","qty":400,"unit":"grams"},{"name":"Tomato","qty":3,"unit":"units"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Onion","qty":1,"unit":"unit"}]},{"id":15,"name":"Fatteh","category":"Appetizer","ingredients":[{"name":"Chickpeas","qty":1,"unit":"cup"},{"name":"Pita Bread","qty":2,"unit":"pieces"},{"name":"Yogurt","qty":1,"unit":"cup"},{"name":"Tahini","qty":2,"unit":"tbsp"},{"name":"Garlic","qty":2,"unit":"cloves"}]},{"id":16,"name":"Sambousek","category":"Snack","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Minced Meat","qty":200,"unit":"grams"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"}]},{"id":17,"name":"Knefeh","category":"Breakfast","ingredients":[{"name":"Cheese","qty":2,"unit":"cups"},{"name":"Semolina","qty":1,"unit":"cup"},{"name":"Butter","qty":3,"unit":"tbsp"},{"name":"Sugar Syrup","qty":0.5,"unit":"cup"},{"name":"Rose Water","qty":1,"unit":"tbsp"}]},{"id":18,"name":"Shish Tawook","category":"Main Dish","ingredients":[{"name":"Chicken","qty":400,"unit":"grams"},{"name":"Yogurt","qty":0.5,"unit":"cup"},{"name":"Garlic","qty":4,"unit":"cloves"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":19,"name":"Laban Immo","category":"Main Dish","ingredients":[{"name":"Lamb","qty":400,"unit":"grams"},{"name":"Yogurt","qty":2,"unit":"cups"},{"name":"Rice","qty":1,"unit":"cup"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Coriander","qty":1,"unit":"tsp"}]},{"id":20,"name":"Moutabal","category":"Appetizer","ingredients":[{"name":"Eggplant","qty":2,"unit":"units"},{"name":"Tahini","qty":3,"unit":"tbsp"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Garlic","qty":1,"unit":"clove"},{"name":"Pomegranate","qty":2,"unit":"tbsp"}]},{"id":21,"name":"Mansaf","category":"Main Dish","ingredients":[{"name":"Lamb","qty":600,"unit":"grams"},{"name":"Jameed","qty":2,"unit":"cups"},{"name":"Rice","qty":2,"unit":"cups"},{"name":"Almonds","qty":0.5,"unit":"cup"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Butter","qty":2,"unit":"tbsp"}]},{"id":22,"name":"Maqluba","category":"Main Dish","ingredients":[{"name":"Chicken","qty":500,"unit":"grams"},{"name":"Eggplant","qty":2,"unit":"units"},{"name":"Rice","qty":2,"unit":"cups"},{"name":"Cauliflower","qty":1,"unit":"head"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Tomato","qty":2,"unit":"units"}]},{"id":23,"name":"Daoud Basha","category":"Main Dish","ingredients":[{"name":"Minced Meat","qty":400,"unit":"grams"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Tomato Paste","qty":2,"unit":"tbsp"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"},{"name":"Pomegranate Molasses","qty":1,"unit":"tbsp"}]},{"id":24,"name":"Hashweh Rice","category":"Main Dish","ingredients":[{"name":"Rice","qty":2,"unit":"cups"},{"name":"Minced Meat","qty":300,"unit":"grams"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Almonds","qty":3,"unit":"tbsp"},{"name":"Cinnamon","qty":1,"unit":"tsp"},{"name":"Butter","qty":2,"unit":"tbsp"}]},{"id":25,"name":"Fasolia","category":"Main Dish","ingredients":[{"name":"White Beans","qty":1,"unit":"cup"},{"name":"Lamb","qty":300,"unit":"grams"},{"name":"Tomato Paste","qty":2,"unit":"tbsp"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Onion","qty":1,"unit":"unit"}]},{"id":26,"name":"Bamia","category":"Main Dish","ingredients":[{"name":"Okra","qty":400,"unit":"grams"},{"name":"Lamb","qty":300,"unit":"grams"},{"name":"Tomato Paste","qty":2,"unit":"tbsp"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Coriander","qty":1,"unit":"tsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"}]},{"id":27,"name":"Chicken Fatteh","category":"Main Dish","ingredients":[{"name":"Chicken","qty":500,"unit":"grams"},{"name":"Pita Bread","qty":3,"unit":"pieces"},{"name":"Yogurt","qty":2,"unit":"cups"},{"name":"Tahini","qty":3,"unit":"tbsp"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Garlic","qty":2,"unit":"cloves"}]},{"id":28,"name":"Samke Harra","category":"Main Dish","ingredients":[{"name":"Fish","qty":600,"unit":"grams"},{"name":"Tahini","qty":4,"unit":"tbsp"},{"name":"Lemon Juice","qty":3,"unit":"tbsp"},{"name":"Garlic","qty":4,"unit":"cloves"},{"name":"Chilli","qty":2,"unit":"units"},{"name":"Coriander","qty":1,"unit":"tsp"}]},{"id":29,"name":"Grilled Hammour","category":"Main Dish","ingredients":[{"name":"Fish","qty":600,"unit":"grams"},{"name":"Olive Oil","qty":3,"unit":"tbsp"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Cumin","qty":1,"unit":"tsp"},{"name":"Parsley","qty":2,"unit":"tbsp"}]},{"id":30,"name":"Freekeh Chicken","category":"Main Dish","ingredients":[{"name":"Chicken","qty":500,"unit":"grams"},{"name":"Freekeh","qty":2,"unit":"cups"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Almonds","qty":3,"unit":"tbsp"},{"name":"Cinnamon","qty":1,"unit":"tsp"}]},{"id":31,"name":"Stuffed Zucchini","category":"Main Dish","ingredients":[{"name":"Zucchini","qty":6,"unit":"units"},{"name":"Minced Meat","qty":300,"unit":"grams"},{"name":"Rice","qty":0.5,"unit":"cup"},{"name":"Tomato Paste","qty":2,"unit":"tbsp"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"},{"name":"Pine Nuts","qty":2,"unit":"tbsp"}]},{"id":32,"name":"Musakhan","category":"Main Dish","ingredients":[{"name":"Chicken","qty":500,"unit":"grams"},{"name":"Onion","qty":4,"unit":"units"},{"name":"Sumac","qty":3,"unit":"tbsp"},{"name":"Pita Bread","qty":3,"unit":"pieces"},{"name":"Olive Oil","qty":4,"unit":"tbsp"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"}]},{"id":33,"name":"Koshari","category":"Main Dish","ingredients":[{"name":"Rice","qty":1,"unit":"cup"},{"name":"Lentils","qty":0.5,"unit":"cup"},{"name":"Pasta","qty":1,"unit":"cup"},{"name":"Tomato Paste","qty":3,"unit":"tbsp"},{"name":"Onion","qty":2,"unit":"units"},{"name":"Garlic","qty":3,"unit":"cloves"}]},{"id":34,"name":"Chicken Kabsa","category":"Main Dish","ingredients":[{"name":"Chicken","qty":600,"unit":"grams"},{"name":"Rice","qty":2,"unit":"cups"},{"name":"Tomato","qty":2,"unit":"units"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Cardamom","qty":2,"unit":"pods"},{"name":"Saffron","qty":0.5,"unit":"tsp"}]},{"id":35,"name":"Lamb Ouzi","category":"Main Dish","ingredients":[{"name":"Lamb","qty":1,"unit":"kg"},{"name":"Rice","qty":2,"unit":"cups"},{"name":"Almonds","qty":0.5,"unit":"cup"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Cardamom","qty":3,"unit":"pods"},{"name":"Butter","qty":3,"unit":"tbsp"}]},{"id":36,"name":"Arayes","category":"Main Dish","ingredients":[{"name":"Pita Bread","qty":4,"unit":"pieces"},{"name":"Minced Meat","qty":400,"unit":"grams"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Parsley","qty":0.5,"unit":"cup"},{"name":"Tomato","qty":1,"unit":"unit"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":37,"name":"Chicken Muhammar","category":"Main Dish","ingredients":[{"name":"Chicken","qty":500,"unit":"grams"},{"name":"Rice","qty":2,"unit":"cups"},{"name":"Saffron","qty":0.5,"unit":"tsp"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Cardamom","qty":2,"unit":"pods"},{"name":"Butter","qty":2,"unit":"tbsp"}]},{"id":38,"name":"Molokhia","category":"Main Dish","ingredients":[{"name":"Molokhia","qty":400,"unit":"grams"},{"name":"Chicken","qty":400,"unit":"grams"},{"name":"Garlic","qty":6,"unit":"cloves"},{"name":"Coriander","qty":2,"unit":"tsp"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Rice","qty":1,"unit":"cup"}]},{"id":39,"name":"Batata Harra","category":"Side Dish","ingredients":[{"name":"Potato","qty":4,"unit":"units"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Chilli","qty":2,"unit":"units"},{"name":"Coriander","qty":1,"unit":"cup"},{"name":"Olive Oil","qty":3,"unit":"tbsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"}]},{"id":40,"name":"Stuffed Peppers","category":"Main Dish","ingredients":[{"name":"Bell Pepper","qty":6,"unit":"units"},{"name":"Minced Meat","qty":300,"unit":"grams"},{"name":"Rice","qty":0.5,"unit":"cup"},{"name":"Tomato Paste","qty":2,"unit":"tbsp"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Parsley","qty":0.25,"unit":"cup"}]},{"id":41,"name":"Mashed Potatoes","category":"Side Dish","ingredients":[{"name":"Potato","qty":4,"unit":"units"},{"name":"Butter","qty":2,"unit":"tbsp"},{"name":"Milk","qty":0.5,"unit":"cup"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Salt","qty":1,"unit":"tsp"}]},{"id":42,"name":"Fried Cauliflower","category":"Side Dish","ingredients":[{"name":"Cauliflower","qty":1,"unit":"head"},{"name":"Olive Oil","qty":3,"unit":"tbsp"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Tahini","qty":2,"unit":"tbsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"}]},{"id":43,"name":"Sabanekh","category":"Side Dish","ingredients":[{"name":"Spinach","qty":400,"unit":"grams"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"},{"name":"Pine Nuts","qty":2,"unit":"tbsp"}]},{"id":44,"name":"Rocca Salad","category":"Side Dish","ingredients":[{"name":"Rocket","qty":200,"unit":"grams"},{"name":"Tomato","qty":2,"unit":"units"},{"name":"Parmesan","qty":3,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"}]},{"id":45,"name":"Lebanese Rice","category":"Side Dish","ingredients":[{"name":"Rice","qty":2,"unit":"cups"},{"name":"Vermicelli","qty":0.5,"unit":"cup"},{"name":"Butter","qty":2,"unit":"tbsp"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Almonds","qty":3,"unit":"tbsp"}]},{"id":46,"name":"Bazella","category":"Side Dish","ingredients":[{"name":"Green Peas","qty":400,"unit":"grams"},{"name":"Minced Meat","qty":200,"unit":"grams"},{"name":"Tomato Paste","qty":2,"unit":"tbsp"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"}]},{"id":47,"name":"Courgette Salad","category":"Side Dish","ingredients":[{"name":"Zucchini","qty":3,"unit":"units"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Mint","qty":1,"unit":"tbsp"}]},{"id":48,"name":"Muhamara","category":"Appetizer","ingredients":[{"name":"Red Pepper","qty":3,"unit":"units"},{"name":"Walnuts","qty":0.5,"unit":"cup"},{"name":"Pomegranate Molasses","qty":1,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Cumin","qty":0.5,"unit":"tsp"},{"name":"Chilli","qty":1,"unit":"unit"}]},{"id":49,"name":"Potato Salad","category":"Side Dish","ingredients":[{"name":"Potato","qty":4,"unit":"units"},{"name":"Parsley","qty":0.5,"unit":"cup"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Onion","qty":0.5,"unit":"unit"}]},{"id":50,"name":"Cucumber Salad","category":"Side Dish","ingredients":[{"name":"Cucumber","qty":3,"unit":"units"},{"name":"Yogurt","qty":1,"unit":"cup"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Mint","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":1,"unit":"tbsp"}]},{"id":51,"name":"Labneh","category":"Appetizer","ingredients":[{"name":"Yogurt","qty":2,"unit":"cups"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Zaatar","qty":1,"unit":"tbsp"},{"name":"Salt","qty":1,"unit":"tsp"}]},{"id":52,"name":"Kibbeh Nayyeh","category":"Appetizer","ingredients":[{"name":"Minced Meat","qty":300,"unit":"grams"},{"name":"Bulgur","qty":0.5,"unit":"cup"},{"name":"Onion","qty":0.5,"unit":"unit"},{"name":"Mint","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":53,"name":"Shanklish","category":"Appetizer","ingredients":[{"name":"Shanklish Cheese","qty":200,"unit":"grams"},{"name":"Tomato","qty":2,"unit":"units"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Zaatar","qty":1,"unit":"tbsp"}]},{"id":54,"name":"Walnuts Salad","category":"Appetizer","ingredients":[{"name":"Walnuts","qty":1,"unit":"cup"},{"name":"Pomegranate","qty":1,"unit":"unit"},{"name":"Parsley","qty":0.5,"unit":"cup"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"}]},{"id":55,"name":"Stuffed Mushrooms","category":"Appetizer","ingredients":[{"name":"Mushrooms","qty":12,"unit":"units"},{"name":"Minced Meat","qty":200,"unit":"grams"},{"name":"Onion","qty":0.5,"unit":"unit"},{"name":"Pine Nuts","qty":2,"unit":"tbsp"},{"name":"Parsley","qty":3,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":56,"name":"Cheese Rolls","category":"Snack","ingredients":[{"name":"Spring Roll Pastry","qty":10,"unit":"sheets"},{"name":"Cheese","qty":1,"unit":"cup"},{"name":"Parsley","qty":3,"unit":"tbsp"},{"name":"Egg","qty":1,"unit":"unit"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":57,"name":"Lentil Soup","category":"Appetizer","ingredients":[{"name":"Red Lentils","qty":1,"unit":"cup"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Cumin","qty":1,"unit":"tsp"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":58,"name":"Freekeh Soup","category":"Appetizer","ingredients":[{"name":"Freekeh","qty":1,"unit":"cup"},{"name":"Chicken","qty":300,"unit":"grams"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"},{"name":"Cardamom","qty":1,"unit":"pod"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":59,"name":"Harira","category":"Appetizer","ingredients":[{"name":"Chickpeas","qty":0.5,"unit":"cup"},{"name":"Red Lentils","qty":0.5,"unit":"cup"},{"name":"Tomato","qty":3,"unit":"units"},{"name":"Coriander","qty":1,"unit":"tsp"},{"name":"Celery","qty":2,"unit":"stalks"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"}]},{"id":60,"name":"Spinach Fatayer","category":"Snack","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Spinach","qty":300,"unit":"grams"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Sumac","qty":1,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"}]},{"id":61,"name":"Ful Medames","category":"Breakfast","ingredients":[{"name":"Fava Beans","qty":1,"unit":"cup"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Cumin","qty":1,"unit":"tsp"},{"name":"Parsley","qty":3,"unit":"tbsp"}]},{"id":62,"name":"Shakshuka","category":"Breakfast","ingredients":[{"name":"Egg","qty":4,"unit":"units"},{"name":"Tomato","qty":4,"unit":"units"},{"name":"Bell Pepper","qty":2,"unit":"units"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Chilli","qty":1,"unit":"unit"}]},{"id":63,"name":"Kaak","category":"Breakfast","ingredients":[{"name":"Flour","qty":3,"unit":"cups"},{"name":"Sesame Seeds","qty":4,"unit":"tbsp"},{"name":"Butter","qty":3,"unit":"tbsp"},{"name":"Sugar","qty":2,"unit":"tbsp"},{"name":"Anise","qty":1,"unit":"tsp"}]},{"id":64,"name":"Avocado Toast","category":"Breakfast","ingredients":[{"name":"Avocado","qty":2,"unit":"units"},{"name":"Bread","qty":2,"unit":"slices"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"},{"name":"Olive Oil","qty":1,"unit":"tbsp"},{"name":"Salt","qty":0.5,"unit":"tsp"}]},{"id":65,"name":"Cheese Omelette","category":"Breakfast","ingredients":[{"name":"Egg","qty":3,"unit":"units"},{"name":"Cheese","qty":0.5,"unit":"cup"},{"name":"Butter","qty":1,"unit":"tbsp"},{"name":"Parsley","qty":2,"unit":"tbsp"},{"name":"Salt","qty":0.5,"unit":"tsp"}]},{"id":66,"name":"Msabbaha","category":"Breakfast","ingredients":[{"name":"Chickpeas","qty":1,"unit":"cup"},{"name":"Tahini","qty":3,"unit":"tbsp"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Cumin","qty":0.5,"unit":"tsp"},{"name":"Parsley","qty":3,"unit":"tbsp"}]},{"id":67,"name":"Halloumi Sandwich","category":"Breakfast","ingredients":[{"name":"Halloumi","qty":200,"unit":"grams"},{"name":"Bread","qty":2,"unit":"slices"},{"name":"Tomato","qty":1,"unit":"unit"},{"name":"Mint","qty":1,"unit":"tbsp"},{"name":"Olive Oil","qty":1,"unit":"tbsp"}]},{"id":68,"name":"Labneh Sandwich","category":"Breakfast","ingredients":[{"name":"Yogurt","qty":1,"unit":"cup"},{"name":"Bread","qty":2,"unit":"slices"},{"name":"Tomato","qty":1,"unit":"unit"},{"name":"Cucumber","qty":1,"unit":"unit"},{"name":"Olive Oil","qty":1,"unit":"tbsp"},{"name":"Zaatar","qty":1,"unit":"tsp"}]},{"id":69,"name":"Manakish Spinach","category":"Breakfast","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Spinach","qty":200,"unit":"grams"},{"name":"Cheese","qty":0.5,"unit":"cup"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Onion","qty":0.5,"unit":"unit"}]},{"id":70,"name":"Bayd Bil Awarma","category":"Breakfast","ingredients":[{"name":"Egg","qty":4,"unit":"units"},{"name":"Awarma","qty":3,"unit":"tbsp"},{"name":"Butter","qty":1,"unit":"tbsp"},{"name":"Salt","qty":0.5,"unit":"tsp"}]},{"id":71,"name":"Chicken Wings","category":"Snack","ingredients":[{"name":"Chicken Wings","qty":500,"unit":"grams"},{"name":"Garlic","qty":3,"unit":"cloves"},{"name":"Lemon Juice","qty":2,"unit":"tbsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Cumin","qty":1,"unit":"tsp"},{"name":"Chilli","qty":1,"unit":"tsp"}]},{"id":72,"name":"Meat Sambousek","category":"Snack","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Minced Meat","qty":250,"unit":"grams"},{"name":"Pine Nuts","qty":2,"unit":"tbsp"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"},{"name":"Butter","qty":2,"unit":"tbsp"}]},{"id":73,"name":"Cheese Fatayer","category":"Snack","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Cheese","qty":1,"unit":"cup"},{"name":"Egg","qty":1,"unit":"unit"},{"name":"Butter","qty":2,"unit":"tbsp"},{"name":"Parsley","qty":3,"unit":"tbsp"}]},{"id":74,"name":"Kibbeh Balls","category":"Snack","ingredients":[{"name":"Minced Meat","qty":300,"unit":"grams"},{"name":"Bulgur","qty":1,"unit":"cup"},{"name":"Onion","qty":1,"unit":"unit"},{"name":"Pine Nuts","qty":3,"unit":"tbsp"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"},{"name":"Olive Oil","qty":2,"unit":"tbsp"}]},{"id":75,"name":"Roasted Chickpeas","category":"Snack","ingredients":[{"name":"Chickpeas","qty":2,"unit":"cups"},{"name":"Olive Oil","qty":2,"unit":"tbsp"},{"name":"Cumin","qty":1,"unit":"tsp"},{"name":"Paprika","qty":1,"unit":"tsp"},{"name":"Salt","qty":0.5,"unit":"tsp"}]},{"id":76,"name":"Muhammara Dip","category":"Snack","ingredients":[{"name":"Red Pepper","qty":3,"unit":"units"},{"name":"Walnuts","qty":0.5,"unit":"cup"},{"name":"Breadcrumbs","qty":3,"unit":"tbsp"},{"name":"Olive Oil","qty":3,"unit":"tbsp"},{"name":"Lemon Juice","qty":1,"unit":"tbsp"},{"name":"Cumin","qty":0.5,"unit":"tsp"}]},{"id":77,"name":"Potato Wedges","category":"Snack","ingredients":[{"name":"Potato","qty":4,"unit":"units"},{"name":"Olive Oil","qty":3,"unit":"tbsp"},{"name":"Garlic","qty":2,"unit":"cloves"},{"name":"Paprika","qty":1,"unit":"tsp"},{"name":"Cumin","qty":0.5,"unit":"tsp"},{"name":"Salt","qty":1,"unit":"tsp"}]},{"id":78,"name":"Corn Cheese","category":"Snack","ingredients":[{"name":"Corn","qty":2,"unit":"cups"},{"name":"Cheese","qty":1,"unit":"cup"},{"name":"Butter","qty":1,"unit":"tbsp"},{"name":"Milk","qty":0.25,"unit":"cup"},{"name":"Salt","qty":0.5,"unit":"tsp"}]},{"id":79,"name":"Stuffed Dates","category":"Snack","ingredients":[{"name":"Dates","qty":20,"unit":"units"},{"name":"Walnuts","qty":0.5,"unit":"cup"},{"name":"Almonds","qty":0.5,"unit":"cup"},{"name":"Rose Water","qty":1,"unit":"tsp"}]},{"id":80,"name":"Sesame Rings","category":"Snack","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Sesame Seeds","qty":4,"unit":"tbsp"},{"name":"Olive Oil","qty":3,"unit":"tbsp"},{"name":"Sugar","qty":1,"unit":"tbsp"},{"name":"Anise","qty":0.5,"unit":"tsp"}]},{"id":81,"name":"Baklava","category":"Dessert","ingredients":[{"name":"Phyllo Dough","qty":1,"unit":"pack"},{"name":"Walnuts","qty":2,"unit":"cups"},{"name":"Butter","qty":1,"unit":"cup"},{"name":"Sugar Syrup","qty":1,"unit":"cup"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Cinnamon","qty":0.5,"unit":"tsp"}]},{"id":82,"name":"Maamoul","category":"Dessert","ingredients":[{"name":"Semolina","qty":2,"unit":"cups"},{"name":"Butter","qty":1,"unit":"cup"},{"name":"Dates","qty":1,"unit":"cup"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Orange Blossom Water","qty":1,"unit":"tbsp"},{"name":"Sugar","qty":3,"unit":"tbsp"}]},{"id":83,"name":"Awamat","category":"Dessert","ingredients":[{"name":"Flour","qty":1,"unit":"cup"},{"name":"Yeast","qty":1,"unit":"tsp"},{"name":"Sugar Syrup","qty":1,"unit":"cup"},{"name":"Olive Oil","qty":2,"unit":"cups"},{"name":"Rose Water","qty":1,"unit":"tbsp"}]},{"id":84,"name":"Halawet El Jibn","category":"Dessert","ingredients":[{"name":"Cheese","qty":2,"unit":"cups"},{"name":"Semolina","qty":0.5,"unit":"cup"},{"name":"Sugar Syrup","qty":1,"unit":"cup"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Clotted Cream","qty":1,"unit":"cup"}]},{"id":85,"name":"Moghli","category":"Dessert","ingredients":[{"name":"Rice Flour","qty":0.5,"unit":"cup"},{"name":"Sugar","qty":0.5,"unit":"cup"},{"name":"Cinnamon","qty":1,"unit":"tsp"},{"name":"Caraway","qty":1,"unit":"tsp"},{"name":"Walnuts","qty":3,"unit":"tbsp"},{"name":"Coconut","qty":3,"unit":"tbsp"}]},{"id":86,"name":"Layali Lubnan","category":"Dessert","ingredients":[{"name":"Semolina","qty":0.5,"unit":"cup"},{"name":"Milk","qty":2,"unit":"cups"},{"name":"Sugar","qty":3,"unit":"tbsp"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Clotted Cream","qty":1,"unit":"cup"},{"name":"Pistachios","qty":3,"unit":"tbsp"}]},{"id":87,"name":"Riz Bi Haleeb","category":"Dessert","ingredients":[{"name":"Rice","qty":0.5,"unit":"cup"},{"name":"Milk","qty":3,"unit":"cups"},{"name":"Sugar","qty":4,"unit":"tbsp"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Pistachios","qty":2,"unit":"tbsp"}]},{"id":88,"name":"Sfouf","category":"Dessert","ingredients":[{"name":"Flour","qty":2,"unit":"cups"},{"name":"Semolina","qty":0.5,"unit":"cup"},{"name":"Turmeric","qty":1,"unit":"tsp"},{"name":"Sugar","qty":0.5,"unit":"cup"},{"name":"Olive Oil","qty":0.5,"unit":"cup"},{"name":"Sesame Seeds","qty":2,"unit":"tbsp"}]},{"id":89,"name":"Karabij","category":"Dessert","ingredients":[{"name":"Semolina","qty":2,"unit":"cups"},{"name":"Pistachios","qty":1,"unit":"cup"},{"name":"Butter","qty":0.5,"unit":"cup"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Orange Blossom Water","qty":1,"unit":"tbsp"},{"name":"Sugar","qty":3,"unit":"tbsp"}]},{"id":90,"name":"Nammoura","category":"Dessert","ingredients":[{"name":"Semolina","qty":2,"unit":"cups"},{"name":"Yogurt","qty":0.5,"unit":"cup"},{"name":"Sugar Syrup","qty":1,"unit":"cup"},{"name":"Butter","qty":0.5,"unit":"cup"},{"name":"Almonds","qty":3,"unit":"tbsp"},{"name":"Rose Water","qty":1,"unit":"tbsp"}]},{"id":91,"name":"Jallab","category":"Drink","ingredients":[{"name":"Grape Juice","qty":1,"unit":"cup"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Pine Nuts","qty":1,"unit":"tbsp"},{"name":"Raisins","qty":1,"unit":"tbsp"},{"name":"Sugar","qty":1,"unit":"tbsp"}]},{"id":92,"name":"Lemonade Mint","category":"Drink","ingredients":[{"name":"Lemon Juice","qty":4,"unit":"tbsp"},{"name":"Mint","qty":10,"unit":"leaves"},{"name":"Sugar","qty":2,"unit":"tbsp"},{"name":"Water","qty":2,"unit":"cups"}]},{"id":93,"name":"Tamarind Drink","category":"Drink","ingredients":[{"name":"Tamarind","qty":3,"unit":"tbsp"},{"name":"Sugar","qty":2,"unit":"tbsp"},{"name":"Water","qty":2,"unit":"cups"},{"name":"Rose Water","qty":0.5,"unit":"tbsp"}]},{"id":94,"name":"Ayran","category":"Drink","ingredients":[{"name":"Yogurt","qty":1,"unit":"cup"},{"name":"Water","qty":0.5,"unit":"cup"},{"name":"Salt","qty":0.5,"unit":"tsp"},{"name":"Mint","qty":1,"unit":"tsp"}]},{"id":95,"name":"Sahlab","category":"Drink","ingredients":[{"name":"Milk","qty":2,"unit":"cups"},{"name":"Sugar","qty":2,"unit":"tbsp"},{"name":"Sahlab Powder","qty":2,"unit":"tbsp"},{"name":"Rose Water","qty":1,"unit":"tbsp"},{"name":"Pistachios","qty":1,"unit":"tbsp"},{"name":"Cinnamon","qty":0.25,"unit":"tsp"}]},{"id":96,"name":"Karak Chai","category":"Drink","ingredients":[{"name":"Black Tea","qty":2,"unit":"tsp"},{"name":"Milk","qty":1,"unit":"cup"},{"name":"Cardamom","qty":2,"unit":"pods"},{"name":"Sugar","qty":2,"unit":"tbsp"},{"name":"Water","qty":0.5,"unit":"cup"}]},{"id":97,"name":"Mint Tea","category":"Drink","ingredients":[{"name":"Mint","qty":10,"unit":"leaves"},{"name":"Black Tea","qty":1,"unit":"tsp"},{"name":"Sugar","qty":2,"unit":"tbsp"},{"name":"Water","qty":2,"unit":"cups"}]},{"id":98,"name":"Carob Juice","category":"Drink","ingredients":[{"name":"Carob Molasses","qty":2,"unit":"tbsp"},{"name":"Water","qty":2,"unit":"cups"},{"name":"Rose Water","qty":0.5,"unit":"tbsp"},{"name":"Sugar","qty":1,"unit":"tbsp"}]},{"id":99,"name":"Laban","category":"Drink","ingredients":[{"name":"Yogurt","qty":2,"unit":"cups"},{"name":"Water","qty":1,"unit":"cup"},{"name":"Salt","qty":0.5,"unit":"tsp"},{"name":"Dried Mint","qty":0.5,"unit":"tsp"}]},{"id":100,"name":"Qamar El Din","category":"Drink","ingredients":[{"name":"Apricot Paste","qty":3,"unit":"tbsp"},{"name":"Water","qty":2,"unit":"cups"},{"name":"Sugar","qty":1,"unit":"tbsp"},{"name":"Rose Water","qty":0.5,"unit":"tbsp"}]}]
''';

// ── Local models ───────────────────────────────────────────────────────────────
class LocalIngredient {
  final String name;
  final double qty;
  final String unit;
  const LocalIngredient({required this.name, required this.qty, required this.unit});
  factory LocalIngredient.fromJson(Map<String, dynamic> j) => LocalIngredient(
        name: j['name'] ?? '',
        qty: double.parse(j['qty'].toString()),
        unit: j['unit'] ?? '',
      );
}

class LocalRecipe {
  final int id;
  final String name;
  final String category;
  final List<LocalIngredient> ingredients;
  const LocalRecipe({required this.id, required this.name, required this.category, required this.ingredients});
  factory LocalRecipe.fromJson(Map<String, dynamic> j) => LocalRecipe(
        id: j['id'] as int,
        name: j['name'] ?? '',
        category: j['category'] ?? '',
        ingredients: (j['ingredients'] as List).map((i) => LocalIngredient.fromJson(i)).toList(),
      );
}

// ── API model ──────────────────────────────────────────────────────────────────
class RecommendedRecipe {
  final String dishName;
  final String category;
  final List<String> matchedIngredients;
  final double cosineScore;
  final double urgencyScore;
  final double finalScore;
  final String matchPct;

  const RecommendedRecipe({
    required this.dishName,
    required this.category,
    required this.matchedIngredients,
    required this.cosineScore,
    required this.urgencyScore,
    required this.finalScore,
    required this.matchPct,
  });

  factory RecommendedRecipe.fromJson(Map<String, dynamic> json) {
    return RecommendedRecipe(
      dishName: json['dish_name'] ?? '',
      category: json['category'] ?? '',
      matchedIngredients: List<String>.from(json['matched_ingredients'] ?? []),
      cosineScore: double.parse(json['cosine_score'].toString()),
      urgencyScore: double.parse(json['urgency_score'].toString()),
      finalScore: double.parse(json['final_score'].toString()),
      matchPct: json['match_pct'] ?? '',
    );
  }

  IconData get categoryIcon => _categoryIcon(category);
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'main dish': return Icons.restaurant_rounded;
    case 'side dish': return Icons.grass_rounded;
    case 'appetizer': return Icons.soup_kitchen_rounded;
    case 'dessert': return Icons.cake_rounded;
    case 'breakfast': return Icons.free_breakfast_rounded;
    case 'snack': return Icons.cookie_rounded;
    case 'drink': return Icons.local_drink_rounded;
    default: return Icons.local_dining_rounded;
  }
}

enum _TabMode { aiRecommended, allRecipes }

// ── Screen ────────────────────────────────────────────────────────────────────
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<RecommendedRecipe> _apiRecipes = [];
  bool _apiLoading = true;
  String? _apiError;

  late final List<LocalRecipe> _localRecipes;
  List<LocalRecipe> _filteredLocal = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  String _selectedCategory = 'All';
  _TabMode _tab = _TabMode.aiRecommended;
  bool _ingredientMode = false;

  String get _apiUrl => ApiConfig.getRecipes;

  @override
  void initState() {
    super.initState();
    final raw = jsonDecode(_kRecipesJson) as List;
    _localRecipes = raw.map((j) => LocalRecipe.fromJson(j)).toList();
    _filteredLocal = List.from(_localRecipes);
    _fetchApiRecipes();
    _searchController.addListener(_applyLocalFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _fetchApiRecipes() async {
    setState(() { _apiLoading = true; _apiError = null; });
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _apiRecipes = data.map((j) => RecommendedRecipe.fromJson(j)).toList();
          _apiLoading = false;
        });
      } else {
        setState(() { _apiError = 'Server error: ${response.statusCode}'; _apiLoading = false; });
      }
    } catch (e) {
      setState(() { _apiError = 'Could not reach server.\n$e'; _apiLoading = false; });
    }
  }

  void _applyLocalFilter() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredLocal = _localRecipes.where((r) {
        final matchesSearch = q.isEmpty ||
            r.name.toLowerCase().contains(q) ||
            r.ingredients.any((i) => i.name.toLowerCase().contains(q));
        final matchesCat = _selectedCategory == 'All' || r.category == _selectedCategory;
        return matchesSearch && matchesCat;
      }).toList();
    });
  }

  void _selectCategory(String cat) {
    setState(() => _selectedCategory = cat);
    _applyLocalFilter();
  }

  List<LocalRecipe> _searchByIngredients(String raw) {
    final terms = raw.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
    if (terms.isEmpty) return [];
    final scored = <(LocalRecipe, int)>[];
    for (final r in _localRecipes) {
      final recipeIngs = r.ingredients.map((i) => i.name.toLowerCase()).toList();
      int matches = 0;
      for (final t in terms) {
        if (recipeIngs.any((ri) => ri.contains(t) || t.contains(ri))) matches++;
      }
      if (matches > 0) scored.add((r, matches));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  List<String> get _categories {
    final cats = _localRecipes.map((r) => r.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  void _showLocalDetail(LocalRecipe recipe, {Set<String> userIngredients = const {}}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RecipeDetailSheet(recipe: recipe, userIngredients: userIngredients),
    );
  }

  void _showApiDetail(RecommendedRecipe recipe) {
    final local = _localRecipes.firstWhere(
      (r) => r.name.toLowerCase() == recipe.dishName.toLowerCase(),
      orElse: () => LocalRecipe(id: 0, name: recipe.dishName, category: recipe.category, ingredients: []),
    );
    final matchedSet = recipe.matchedIngredients.map((s) => s.toLowerCase()).toSet();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RecipeDetailSheet(
        recipe: local.id == 0
            ? LocalRecipe(
                id: 0,
                name: recipe.dishName,
                category: recipe.category,
                ingredients: recipe.matchedIngredients
                    .map((m) => LocalIngredient(name: m, qty: 0, unit: ''))
                    .toList(),
              )
            : local,
        userIngredients: matchedSet,
        apiRecipe: recipe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Fixed header ─────────────────────────────────────────────────
          AppHeader(
            title: "Today's Menu",
            subtitle: 'R E C E N S',
            onRefresh: _fetchApiRecipes,
            onNotification: null,
          ),

          // ── Tab + search bar — first item below the header ────────────
          SliverToBoxAdapter(
            child: _TopBar(
              searchController: _searchController,
              tab: _tab,
              ingredientMode: _ingredientMode,
              onTabChanged: (t) {
                setState(() {
                  _tab = t;
                  if (t == _TabMode.allRecipes) {
                    _ingredientMode = false;
                    _applyLocalFilter();
                  }
                });
              },
              onIngredientModeChanged: (v) => setState(() => _ingredientMode = v),
            ),
          ),

          if (_tab == _TabMode.aiRecommended)
            ..._buildApiBody()
          else
            ..._buildAllRecipesBody(),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  List<Widget> _buildApiBody() {
    if (_apiLoading) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.medium)))];
    }
    if (_apiError != null) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  Text(_apiError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _fetchApiRecipes, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        )
      ];
    }

    final Map<String, List<RecommendedRecipe>> grouped = {};
    for (final r in _apiRecipes) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.recipeUrgentBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.recipeUrgentBorder, width: 0.8),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.medium),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Created by AI · Recipes ranked by freshness urgency',
                    style: TextStyle(fontSize: 11, color: AppColors.textSub, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_apiRecipes.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Text('No recipes suggested.', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic, fontSize: 14))),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entries = grouped.entries.toList();
              final entry = entries[index];
              return _RecipeSection<RecommendedRecipe>(
                category: entry.key,
                items: entry.value,
                itemBuilder: (r) => _ApiRecipeRow(recipe: r, onTap: () => _showApiDetail(r)),
              );
            },
            childCount: grouped.length,
          ),
        ),
    ];
  }

  List<Widget> _buildAllRecipesBody() {
    if (_ingredientMode) {
      return [_buildIngredientSearchBody()];
    }

    final Map<String, List<LocalRecipe>> grouped = {};
    for (final r in _filteredLocal) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return [
      SliverToBoxAdapter(
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => _selectCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : AppColors.textSub,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      if (_filteredLocal.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Text('No recipes found.', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic, fontSize: 14))),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entries = grouped.entries.toList();
              final entry = entries[index];
              return _RecipeSection<LocalRecipe>(
                category: entry.key,
                items: entry.value,
                itemBuilder: (r) => _LocalRecipeRow(recipe: r, userIngredients: const {}, onTap: () => _showLocalDetail(r)),
              );
            },
            childCount: grouped.length,
          ),
        ),
    ];
  }

  Widget _buildIngredientSearchBody() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: TextField(
                controller: _ingredientsController,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Type ingredients separated by commas…\ne.g. chicken, garlic, lemon',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(Icons.kitchen_rounded, size: 18, color: AppColors.textMuted),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(0, 12, 16, 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Find Recipes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
            Builder(builder: (_) {
              final query = _ingredientsController.text.trim();
              if (query.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: const [
                        Icon(Icons.set_meal_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Enter ingredients above to\nfind matching recipes',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final results = _searchByIngredients(query);
              final userIngs = query.split(',').map((s) => s.trim().toLowerCase()).toSet();
              if (results.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No recipes match those ingredients.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${results.length} recipe${results.length == 1 ? '' : 's'} found',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  ...results.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _LocalRecipeRow(
                          recipe: r,
                          userIngredients: userIngs,
                          onTap: () => _showLocalDetail(r, userIngredients: userIngs),
                        ),
                      )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar (search + tabs) — now a plain widget below the header ─────────────
class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final _TabMode tab;
  final bool ingredientMode;
  final void Function(_TabMode) onTabChanged;
  final void Function(bool) onIngredientModeChanged;

  const _TopBar({
    required this.searchController,
    required this.tab,
    required this.ingredientMode,
    required this.onTabChanged,
    required this.onIngredientModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              opacity: (tab == _TabMode.allRecipes && !ingredientMode) ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !(tab == _TabMode.allRecipes && !ingredientMode),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search recipes…',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _TabBtn(
            label: 'AI Picks',
            icon: Icons.auto_awesome_rounded,
            active: tab == _TabMode.aiRecommended,
            onTap: () => onTabChanged(_TabMode.aiRecommended),
          ),
          const SizedBox(width: 6),
          _TabBtn(
            label: 'All',
            icon: Icons.menu_book_rounded,
            active: tab == _TabMode.allRecipes && !ingredientMode,
            onTap: () {
              onTabChanged(_TabMode.allRecipes);
              onIngredientModeChanged(false);
            },
          ),
          const SizedBox(width: 6),
          _TabBtn(
            label: 'By Ing.',
            icon: Icons.kitchen_rounded,
            active: tab == _TabMode.allRecipes && ingredientMode,
            onTap: () {
              onTabChanged(_TabMode.allRecipes);
              onIngredientModeChanged(true);
            },
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : AppColors.textSub),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSub)),
          ],
        ),
      ),
    );
  }
}

// ── Generic Section Wrapper ───────────────────────────────────────────────────
class _RecipeSection<T> extends StatelessWidget {
  final String category;
  final List<T> items;
  final Widget Function(T) itemBuilder;

  const _RecipeSection({required this.category, required this.items, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 20, height: 0.8, color: AppColors.divider),
            const SizedBox(width: 10),
            Text(category.toUpperCase(),
                style: const TextStyle(fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.w700, color: AppColors.medium)),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 0.8, color: AppColors.divider)),
          ]),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final isLast = e.key == items.length - 1;
                return Column(children: [
                  itemBuilder(e.value),
                  if (!isLast) Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 14), color: AppColors.border),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── API Recipe Row ────────────────────────────────────────────────────────────
class _ApiRecipeRow extends StatelessWidget {
  final RecommendedRecipe recipe;
  final VoidCallback onTap;
  const _ApiRecipeRow({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.8)),
              child: Icon(recipe.categoryIcon, size: 24, color: AppColors.medium),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.dishName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    recipe.matchedIngredients.take(4).join(', ') + (recipe.matchedIngredients.length > 4 ? '…' : ''),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    _Chip(label: '${recipe.matchPct} match', color: AppColors.goodText, bg: AppColors.goodBg),
                    if (recipe.urgencyScore > 0.6) ...[
                      const SizedBox(width: 6),
                      _Chip(label: '🔥 Use soon', color: AppColors.dangerText, bg: AppColors.dangerBg),
                    ],
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Local Recipe Row ──────────────────────────────────────────────────────────
class _LocalRecipeRow extends StatelessWidget {
  final LocalRecipe recipe;
  final Set<String> userIngredients;
  final VoidCallback onTap;

  const _LocalRecipeRow({required this.recipe, required this.userIngredients, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final int matched = userIngredients.isEmpty
        ? recipe.ingredients.length
        : recipe.ingredients.where((i) {
            return userIngredients.any((u) => i.name.toLowerCase().contains(u) || u.contains(i.name.toLowerCase()));
          }).length;
    final int total = recipe.ingredients.length;
    final int missing = total - matched;
    final bool hasUserIngs = userIngredients.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.8)),
              child: Icon(_categoryIcon(recipe.category), size: 24, color: AppColors.medium),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    recipe.ingredients.take(4).map((i) => i.name).join(', ') + (recipe.ingredients.length > 4 ? '…' : ''),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    _Chip(label: '$total ingredient${total == 1 ? '' : 's'}', color: AppColors.textSub, bg: AppColors.surfaceAlt),
                    if (hasUserIngs) ...[
                      const SizedBox(width: 6),
                      _Chip(label: '$matched/$total match', color: AppColors.goodText, bg: AppColors.goodBg),
                      if (missing > 0) ...[
                        const SizedBox(width: 6),
                        _Chip(label: '$missing missing', color: AppColors.spoiledText, bg: AppColors.spoiledBg),
                      ],
                    ],
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Chip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Recipe Detail Sheet ───────────────────────────────────────────────────────
class _RecipeDetailSheet extends StatelessWidget {
  final LocalRecipe recipe;
  final Set<String> userIngredients;
  final RecommendedRecipe? apiRecipe;

  const _RecipeDetailSheet({required this.recipe, required this.userIngredients, this.apiRecipe});

  bool _isPresent(LocalIngredient ing) {
    if (userIngredients.isEmpty && apiRecipe == null) return true;
    final name = ing.name.toLowerCase();
    if (apiRecipe != null) {
      return apiRecipe!.matchedIngredients.any((m) => m.toLowerCase() == name);
    }
    return userIngredients.any((u) => name.contains(u) || u.contains(name));
  }

  @override
  Widget build(BuildContext context) {
    final bool hasContext = userIngredients.isNotEmpty || apiRecipe != null;
    final presentCount = hasContext ? recipe.ingredients.where(_isPresent).length : recipe.ingredients.length;
    final missingCount = recipe.ingredients.length - presentCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.medium], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_categoryIcon(recipe.category), size: 44, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(height: 6),
                          Text(recipe.category, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(recipe.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _Chip(label: recipe.category, color: AppColors.textSub, bg: AppColors.surfaceAlt),
                      if (apiRecipe != null) ...[
                        const SizedBox(width: 8),
                        _Chip(label: '${apiRecipe!.matchPct} match', color: AppColors.goodText, bg: AppColors.goodBg),
                      ],
                    ]),
                    const SizedBox(height: 18),
                    Container(height: 0.8, color: AppColors.border),
                    const SizedBox(height: 18),
                    if (hasContext) ...[
                      Row(children: [
                        _LegendDot(color: AppColors.recipePresentText),
                        const SizedBox(width: 6),
                        const Text('In fridge', style: TextStyle(fontSize: 11, color: AppColors.textSub)),
                        const SizedBox(width: 16),
                        _LegendDot(color: AppColors.recipeMissingText),
                        const SizedBox(width: 6),
                        const Text('Missing', style: TextStyle(fontSize: 11, color: AppColors.textSub)),
                      ]),
                      const SizedBox(height: 12),
                    ],
                    const Text('INGREDIENTS', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: AppColors.medium, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.8)),
                      child: Column(
                        children: recipe.ingredients.asMap().entries.map((e) {
                          final i = e.key;
                          final ing = e.value;
                          final present = _isPresent(ing);
                          final isLast = i == recipe.ingredients.length - 1;
                          return Column(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: hasContext
                                    ? (present ? AppColors.recipePresentBg.withOpacity(0.5) : AppColors.recipeMissingBg.withOpacity(0.4))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.only(
                                  topLeft: i == 0 ? const Radius.circular(14) : Radius.zero,
                                  topRight: i == 0 ? const Radius.circular(14) : Radius.zero,
                                  bottomLeft: isLast ? const Radius.circular(14) : Radius.zero,
                                  bottomRight: isLast ? const Radius.circular(14) : Radius.zero,
                                ),
                              ),
                              child: Row(children: [
                                if (hasContext) ...[
                                  Icon(present ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16,
                                      color: present ? AppColors.recipePresentText : AppColors.recipeMissingText),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(ing.name, style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500,
                                    color: hasContext ? (present ? AppColors.recipePresentText : AppColors.recipeMissingText) : AppColors.textPrimary,
                                  )),
                                ),
                                Text(
                                  '${ing.qty % 1 == 0 ? ing.qty.toInt() : ing.qty} ${ing.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasContext ? (present ? AppColors.recipePresentText.withOpacity(0.7) : AppColors.recipeMissingText.withOpacity(0.6)) : AppColors.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                if (hasContext && !present) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.spoiledBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.spoiledColor.withOpacity(0.3), width: 0.6),
                                    ),
                                    child: const Text('needed', style: TextStyle(fontSize: 9, color: AppColors.spoiledText, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ]),
                            ),
                            if (!isLast) Container(height: 0.5, color: AppColors.border),
                          ]);
                        }).toList(),
                      ),
                    ),
                    if (hasContext) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        _SummaryChip(count: presentCount, label: 'available', textColor: AppColors.recipePresentText, bgColor: AppColors.recipePresentBg),
                        if (missingCount > 0) ...[
                          const SizedBox(width: 10),
                          _SummaryChip(count: missingCount, label: 'still needed', textColor: AppColors.recipeMissingText, bgColor: AppColors.recipeMissingBg),
                        ],
                      ]),
                    ],
                    if (apiRecipe != null) ...[
                      const SizedBox(height: 18),
                      Container(height: 0.8, color: AppColors.border),
                      const SizedBox(height: 18),
                      const Text('AI MATCH DETAILS', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: AppColors.medium, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _DetailRow('Ingredient match', apiRecipe!.matchPct),
                      const SizedBox(height: 8),
                      _DetailRow('Cosine score', apiRecipe!.cosineScore.toStringAsFixed(4)),
                      const SizedBox(height: 8),
                      _DetailRow('Urgency score', apiRecipe!.urgencyScore.toStringAsFixed(4)),
                      const SizedBox(height: 8),
                      _DetailRow('Final score', apiRecipe!.finalScore.toStringAsFixed(4)),
                      const SizedBox(height: 14),
                      FreshnessBar(
                        fraction: double.tryParse(apiRecipe!.matchPct.replaceAll('%', '')) != null
                            ? double.parse(apiRecipe!.matchPct.replaceAll('%', '')) / 100
                            : 0.0,
                        color: AppColors.medium,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color textColor, bgColor;
  const _SummaryChip({required this.count, required this.label, required this.textColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text('$count $label', style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}