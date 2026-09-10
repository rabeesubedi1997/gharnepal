<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Http\Controllers\Controller;
use App\Http\Resources\CostCalculatorScenarioResource;
use App\Models\CostCalculatorScenario;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class CalculatorScenarioController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return CostCalculatorScenarioResource::collection(
            $request->user()->calculatorScenarios()->latest()->get()
        );
    }

    public function destroy(Request $request, CostCalculatorScenario $scenario): Response
    {
        abort_unless($scenario->user_id === $request->user()->id, 403);

        $scenario->delete();

        return response()->noContent();
    }
}
