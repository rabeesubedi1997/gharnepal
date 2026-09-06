<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\UserResource;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    private const ROLE_KEYS = [Role::BUYER, Role::OWNER, Role::AGENT, Role::AGENCY_ADMIN, Role::ADMIN];

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'q' => ['sometimes', 'string', 'max:255'],
            'role' => ['sometimes', Rule::in(self::ROLE_KEYS)],
            'status' => ['sometimes', Rule::in(['active', 'suspended', 'pending'])],
        ]);

        $users = User::query()
            ->with(['roles', 'agencies'])
            ->when($request->filled('q'), function ($query) use ($request) {
                $term = '%' . $request->string('q') . '%';
                $query->where(fn ($q) => $q->where('name', 'like', $term)->orWhere('email', 'like', $term));
            })
            ->when($request->filled('role'), fn ($query) => $query->whereHas(
                'roles',
                fn ($r) => $r->where('key', $request->string('role')),
            ))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->latest()
            ->paginate(20);

        return UserResource::collection($users);
    }

    public function updateStatus(Request $request, User $user): UserResource
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(['active', 'suspended'])],
        ]);

        if ($user->id === $request->user()->id) {
            throw ValidationException::withMessages(['status' => 'You cannot change your own account status.']);
        }

        $user->update(['status' => $data['status']]);

        return new UserResource($user->load(['roles', 'agencies']));
    }

    public function updateRoles(Request $request, User $user): UserResource
    {
        $data = $request->validate([
            'roles' => ['required', 'array', 'min:1'],
            'roles.*' => [Rule::in(self::ROLE_KEYS)],
        ]);

        if ($user->id === $request->user()->id && ! in_array(Role::ADMIN, $data['roles'], true)) {
            throw ValidationException::withMessages(['roles' => 'You cannot remove your own admin role.']);
        }

        $roleIds = Role::whereIn('key', $data['roles'])->pluck('id');
        $user->roles()->sync($roleIds);

        return new UserResource($user->load(['roles', 'agencies']));
    }
}
